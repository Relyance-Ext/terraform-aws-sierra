resource "aws_secretsmanager_secret" "datadog_api_key" {
  count = var.enable_datadog ? 1 : 0

  name = "sierra/datadog/api-key"
  tags = local.default_tags
}

resource "aws_iam_role" "datadog" {
  count = var.enable_datadog ? 1 : 0

  name = "${var.base_name}_Datadog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy" "datadog_sm" {
  count = var.enable_datadog ? 1 : 0

  name = "datadog-secrets-read"
  role = aws_iam_role.datadog[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_secretsmanager_secret.datadog_api_key[0].arn
    }]
  })
}
