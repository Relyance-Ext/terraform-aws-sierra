# Roles and policies which will always be created
locals {

  assumable_roles = (
    var.assume_all_roles
    ? ["*"]
    : [for account_id in var.assumable_account_ids : "arn:aws:iam::${account_id}:role/*"]
  )
}

# Will be used by Relyance code running in pods
resource "aws_iam_role" "main" {
  name = var.base_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Sid    = "EksPodIdentity"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      },
    ]
  })

  tags = local.default_tags
}

# Inline policy for resource assumption.
resource "aws_iam_role_policy" "main" {
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["sts:AssumeRole", "sts:TagSession"]
        Effect   = "Allow",
        Resource = local.assumable_roles
      }
    ]
  })
}


######

resource "aws_iam_role" "reader" {
  name = "${var.base_name}_Reader"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AssumeRole"
        Principal = {
          AWS = local.s3_read_access_principals
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" : random_uuid.reader_external_id.result
          }
        }
      },
    ]
  })
}

resource "random_uuid" "reader_external_id" {}

######

data "aws_iam_policy_document" "sci_assume_role_with_web_identity" {
  dynamic "statement" {
    for_each = var.code_analysis_enabled ? [0] : []
    content {
      principals {
        type        = "Federated"
        identifiers = ["accounts.google.com"]
      }

      actions = ["sts:AssumeRoleWithWebIdentity"]

      condition {
        test     = "StringEquals"
        variable = "accounts.google.com:oaud"
        values   = [aws_iam_role.main.arn]
      }

      condition {
        test     = "StringEquals"
        variable = "accounts.google.com:aud"
        values   = ["source-code-inspector@${var.gcp_project}.iam.gserviceaccount.com"]
      }
    }
  }
}

resource "aws_iam_role" "sci" {
  count = var.code_analysis_enabled ? 1 : 0

  name               = "${var.base_name}_SCI"
  assume_role_policy = data.aws_iam_policy_document.sci_assume_role_with_web_identity.json
}
