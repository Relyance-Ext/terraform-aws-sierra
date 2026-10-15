# Real local policy-document evaluation; every cloud resource is overridden.
# Apply/teardown manipulate only virtual resources, with fake credentials.
provider "aws" {
  region                      = "us-west-2"
  access_key                  = "fixture"
  secret_key                  = "fixture"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}
override_resource {
  target = aws_s3_bucket.bucket
  values = { id = "findings-fixture", arn = "arn:aws:s3:::findings-fixture" }
}
override_resource {
  target = aws_s3_bucket_policy.bucket
}
override_resource {
  target = aws_s3_bucket_lifecycle_configuration.bucket
}
override_resource {
  target = aws_s3_bucket_versioning.bucket
}
override_resource {
  target = aws_s3_bucket_server_side_encryption_configuration.bucket
}
override_resource {
  target = aws_s3_bucket_public_access_block.bucket
}
variables {
  name                   = "findings-fixture"
  kms_key_arn            = "arn:aws:kms:us-west-2:000000000123:key/fixture"
  expiration_days        = 180
  full_access_principals = ["arn:aws:iam::000000000123:role/scanner"]
  rw_access_principals   = []
  ro_access_principals   = ["arn:aws:iam::000000000123:role/reader"]
  wo_access_principals   = []
}
run "findings_full_access_deletes_reader_remains_ro" {
  command = apply
  assert {
    condition     = alltrue([for action in ["s3:DeleteObject", "s3:DeleteObjectVersion"] : contains(jsondecode(data.aws_iam_policy_document.bucket.json).Statement[0].Action, action)]) && !contains(jsondecode(data.aws_iam_policy_document.bucket.json).Statement[1].Action, "s3:DeleteObject") && !contains(jsondecode(data.aws_iam_policy_document.bucket.json).Statement[1].Action, "s3:DeleteObjectVersion")
    error_message = "Full findings access must permit both deletion forms while reader remains read-only."
  }
  assert {
    condition     = toset(jsondecode(data.aws_iam_policy_document.bucket.json).Statement[0].Resource) == toset(["arn:aws:s3:::findings-fixture", "arn:aws:s3:::findings-fixture/*"])
    error_message = "General deletion must be confined to the dedicated bucket."
  }
}
