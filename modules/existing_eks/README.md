<!-- Everything below this line is output from terraform-docs markdown table -->

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.validate_existing_cluster](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_eks_addon.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon) | data source |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of existing EKS cluster | `string` | n/a | yes |
| <a name="input_require_cluster_addons"></a> [require\_cluster\_addons](#input\_require\_cluster\_addons) | Set true to require that the existing cluster have expected addons | `bool` | n/a | yes |
| <a name="input_require_cluster_auto_mode"></a> [require\_cluster\_auto\_mode](#input\_require\_cluster\_auto\_mode) | Set true to require that the existing cluster be in auto mode | `bool` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_authority"></a> [certificate\_authority](#output\_certificate\_authority) | Certificate authority data for EKS control plane |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | URL of the EKS control plane endpoint |
| <a name="output_oidc_issuer"></a> [oidc\_issuer](#output\_oidc\_issuer) | OIDC URL to be provided to Relyance for cross-cloud access |
<!-- END_TF_DOCS -->
