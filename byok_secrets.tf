# BYOK connection credentials kept in AWS Secrets Manager in this account.
#
# Each InHost BYOK connection can reference a secret by ARN instead of a Kubernetes secret.
# The scanner pods (role aws_iam_role.main, via EKS Pod Identity) read the secret at scan time.
# If write-back is on and a token refresh changes a token, the scanner writes only the changed keys back to the
# same secret, merged onto its current value. A failed write-back is logged and does not fail the scan.
# Nothing here is created unless var.byok_secret_arn_patterns is non-empty.

data "aws_region" "current" {}

# DNS suffix of the partition: amazonaws.com, or amazonaws.com.cn in aws-cn.
data "aws_partition" "current" {}

locals {
  byok_secrets_enabled = length(var.byok_secret_arn_patterns) > 0

  # KMS use is limited to calls that Secrets Manager makes on behalf of the scanner (kms:ViaService).
  # The scanner calls Secrets Manager in the region of each secret's ARN, so the condition must cover the
  # region of every secret that the patterns match.
  # - All patterns have a literal region: allow exactly the module region plus those regions (StringEquals).
  # - Any pattern has a wildcard region (for example "*" or "us-*"): that pattern can match a secret in any
  #   region, and a list of literal regions would make kms:Decrypt fail for secrets outside it. Use StringLike
  #   "secretsmanager.*.<dns suffix>" instead. Use of the keys is still restricted to Secrets Manager, and the
  #   Resource list still restricts which keys; only the region is left open.
  byok_secret_pattern_regions = [
    for arn in var.byok_secret_arn_patterns : length(split(":", arn)) > 3 ? split(":", arn)[3] : ""
  ]
  byok_secret_any_wildcard_region = anytrue([
    for r in local.byok_secret_pattern_regions : length(regexall("^[a-z0-9-]+$", r)) == 0
  ])
  byok_secret_regions = distinct(concat(
    [data.aws_region.current.name],
    [for r in local.byok_secret_pattern_regions : r if length(regexall("^[a-z0-9-]+$", r)) > 0],
  ))
  byok_dns_suffix               = data.aws_partition.current.dns_suffix
  byok_kms_via_service_operator = local.byok_secret_any_wildcard_region ? "StringLike" : "StringEquals"
  byok_kms_via_service_values = (
    local.byok_secret_any_wildcard_region
    ? ["secretsmanager.*.${local.byok_dns_suffix}"]
    : [for r in local.byok_secret_regions : "secretsmanager.${r}.${local.byok_dns_suffix}"]
  )

  byok_secrets_read_actions  = ["secretsmanager:GetSecretValue"]
  byok_secrets_write_actions = var.byok_secret_write_back ? ["secretsmanager:PutSecretValue"] : []

  byok_kms_actions = concat(
    ["kms:Decrypt"],
    var.byok_secret_write_back ? ["kms:GenerateDataKey"] : [],
  )
}

resource "aws_iam_role_policy" "byok_secrets" {
  count = local.byok_secrets_enabled ? 1 : 0

  name = "byok-secrets"
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid      = "ByokSecretsAccess"
        Effect   = "Allow"
        Action   = concat(local.byok_secrets_read_actions, local.byok_secrets_write_actions)
        Resource = var.byok_secret_arn_patterns
      }],
      length(var.byok_secret_kms_key_arns) > 0 ? [{
        Sid      = "ByokSecretsKms"
        Effect   = "Allow"
        Action   = local.byok_kms_actions
        Resource = var.byok_secret_kms_key_arns
        Condition = {
          (local.byok_kms_via_service_operator) = {
            "kms:ViaService" = local.byok_kms_via_service_values
          }
        }
      }] : [],
    )
  })
}
