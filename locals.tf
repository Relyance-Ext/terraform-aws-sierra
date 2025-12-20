# Derived variables used across components
locals {
  terraform_module_version = "0.6.1"

  # Used in validation of var.default_tags
  reserved_tag_prefixes = [
    "aws:",
    "kubernetes.io/",
    "karpenter.sh/",
    "eks.amazonaws.com/"
  ]
  # Updating node pools/groups when we bump version is very disruptive, so let's not do that.
  node_tags = var.default_tags
  default_tags = merge(
    local.node_tags,
    { relyance-inhost = local.terraform_module_version }
  )

  # Per-env principals used by Relyance to retrieve findings data
  per_env_s3_read_access_principals = {
    stage = ["arn:aws:iam::197151328867:user/integration-service-user"]
    prod  = ["arn:aws:iam::580082088342:user/tenant-prod-access"]
  }

  s3_read_access_principals = concat(local.per_env_s3_read_access_principals[var.env], var.s3_read_access_principals)
}
