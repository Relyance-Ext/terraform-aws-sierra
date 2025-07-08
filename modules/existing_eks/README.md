<!-- Everything below this line is output from terraform-docs markdown table -->
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
| <a name="output_cluster"></a> [cluster](#output\_cluster) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_oidc_issuer"></a> [oidc\_issuer](#output\_oidc\_issuer) | OIDC URL to be provided to Relyance for cross-cloud access |
