locals {
  assumable_roles = (
    var.assume_all_roles
    ? ["*"]
    : [for account_id in var.assumable_account_ids : "arn:aws:iam::${account_id}:role/*"]
  )

  standard_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    # TODO: extend this, eventually, for cross-project access
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]
  customer_policies = var.policy != null ? [var.policy] : []

  all_policies = toset(concat(
    local.standard_policies,
    local.customer_policies
  ))
}

resource "aws_iam_role" "main" {
  name = var.base_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
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
        Action   = "sts:AssumeRole",
        Effect   = "Allow",
        Resource = local.assumable_roles
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  for_each = local.all_policies

  role       = aws_iam_role.main.name
  policy_arn = each.value
}

######

resource "aws_iam_role" "eks" {
  name = "${var.base_name}_Cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
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
