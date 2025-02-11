resource "aws_kms_key" "main" {
  description             = "KMS symmetric key for Relyance environment"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = local.default_tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.base_name}"
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_kms_key_policy" "main" {
  key_id = aws_kms_key.main.id
  policy = data.aws_iam_policy_document.main_kms_key.json
}

data "aws_iam_policy_document" "main_kms_key" {
  # Regular use
  statement {
    principals {
      type = "AWS"
      identifiers = concat(
        [aws_iam_role.main.arn],
        [for node_role in aws_iam_role.node : node_role.arn]
      )
    }
    resources = [aws_kms_key.main.arn]
    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext"
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.reader.arn]
    }
    resources = [aws_kms_key.main.arn]
    actions   = ["kms:Decrypt"]
  }

  # Admins need to have ability to manage the key going forward
  statement {
    principals {
      type = "AWS"
      identifiers = [
        data.aws_iam_session_context.current.issuer_arn,
        "arn:aws:iam::${local.account_id}:root",
      ]
    }
    resources = [aws_kms_key.main.arn]
    actions = [
      "kms:*",
    ]
  }
}
