# =============================================================================
#         GAI Buckets
# =============================================================================

# End results, which will be read cross-cloud from GCP
module "findings_bucket" {
  source = "./modules/s3"

  name                   = "relyance-findings-${local.account_id}${var.s3_bucket_suffix}"
  tags                   = local.default_tags
  full_access_principals = []
  rw_access_principals   = [aws_iam_role.main.arn]
  ro_access_principals   = [aws_iam_role.reader.arn]
  wo_access_principals   = []
  kms_key_arn            = aws_kms_key.main.arn
  use_bucket_keys        = var.s3_use_bucket_keys
  expiration_days        = var.s3_expiration_days
}

# Workspace, which will only be accessed locally (with much shorter retention)
module "work_bucket" {
  source = "./modules/s3"

  name                   = "relyance-work-${local.account_id}${var.s3_bucket_suffix}"
  tags                   = local.default_tags
  full_access_principals = [aws_iam_role.main.arn]
  rw_access_principals   = []
  ro_access_principals   = []
  wo_access_principals   = []
  kms_key_arn            = aws_kms_key.main.arn
  use_bucket_keys        = var.s3_use_bucket_keys
  expiration_days        = var.s3_workspace_expiration_days
}

# =============================================================================
#        SCI Bucket
# =============================================================================

module "sci_bucket" {
  source = "./modules/s3"

  name                   = "relyance-sci-${local.account_id}${var.s3_bucket_suffix}"
  tags                   = local.default_tags
  full_access_principals = [aws_iam_role.main.arn]
  rw_access_principals   = []
  ro_access_principals   = []
  wo_access_principals   = [aws_iam_role.sci.arn]
  kms_key_arn            = aws_kms_key.main.arn
  use_bucket_keys        = var.s3_use_bucket_keys
  expiration_days        = var.s3_workspace_expiration_days
}

# NOTE: The SCA process will read from the SCI bucket and write it's findings to the "findings bucket".

