<!-- Everything below this line is output from terraform-docs markdown table -->

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_expiration_days"></a> [expiration\_days](#input\_expiration\_days) | Number of days before objects in bucket expire | `number` | n/a | yes |
| <a name="input_full_access_principals"></a> [full\_access\_principals](#input\_full\_access\_principals) | role/user ARNs with read/write/delete access | `list(string)` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | arn of the KMS key to use to encrypt the bucket | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | globally-unique name of the bucket to be created | `string` | n/a | yes |
| <a name="input_ro_access_principals"></a> [ro\_access\_principals](#input\_ro\_access\_principals) | role/user ARNs with read-only access | `list(string)` | n/a | yes |
| <a name="input_rw_access_principals"></a> [rw\_access\_principals](#input\_rw\_access\_principals) | role/user ARNs with read/write access (but not delete) | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | tags to be applied to resources | `map(string)` | `{}` | no |
| <a name="input_use_bucket_keys"></a> [use\_bucket\_keys](#input\_use\_bucket\_keys) | Enable bucket keys to reduce KMS costs in the S3 findings bucket | `bool` | `true` | no |
| <a name="input_wo_access_principals"></a> [wo\_access\_principals](#input\_wo\_access\_principals) | role/user ARNs with write-only access | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
<!-- END_TF_DOCS -->
