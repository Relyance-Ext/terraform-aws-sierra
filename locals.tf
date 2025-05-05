# Derived variables used across components
locals {
  default_tags = { relyance-sierra = "0.4.0" }

  # Per-env principals used by Relyance to retrieve findings data
  per_env_s3_read_access_principals = {
    stage = ["arn:aws:iam::197151328867:user/integration-service-user"]
    prod  = ["arn:aws:iam::580082088342:user/tenant-prod-access"]
  }

  s3_read_access_principals = concat(local.per_env_s3_read_access_principals[var.env], var.s3_read_access_principals)
}
