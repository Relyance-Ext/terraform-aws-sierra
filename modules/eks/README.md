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
| [aws_eks_access_entry.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_access_policy_association.cluster-admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.kube-proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.metrics-server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.pod-identity-agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc-cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_role.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.allow_tagged_node_creation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_iam_policy_document.allow_tagged_node_creation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_base_name"></a> [base\_name](#input\_base\_name) | Base name used to name EKS cluster and related resources (e.g., IAM roles) | `any` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to non-node AWS resources created in this module | `map(string)` | n/a | yes |
| <a name="input_eks_kubectl_admins"></a> [eks\_kubectl\_admins](#input\_eks\_kubectl\_admins) | Map of custom IAM principal ARNs to be granted kubectl admin access on the EKS cluster | `map(string)` | n/a | yes |
| <a name="input_eks_public_access_cidrs"></a> [eks\_public\_access\_cidrs](#input\_eks\_public\_access\_cidrs) | List of CIDR blocks that are allowed to access the EKS control plane publicly | `list(string)` | n/a | yes |
| <a name="input_eks_require_metadata_token"></a> [eks\_require\_metadata\_token](#input\_eks\_require\_metadata\_token) | Whether to enforce use of IMDSv2 on EC2 nodes for improved security | `bool` | `true` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of KMS symmetric key to encrypt Kubernetes secrets | `string` | n/a | yes |
| <a name="input_node_tags"></a> [node\_tags](#input\_node\_tags) | Default tags to apply to EKS nodes | `map(string)` | n/a | yes |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | CIDR block (at least 16-bits large) for EKS services (null for default autoassign) | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs where EKS worker nodes should be launched | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_auto_node_role_name"></a> [auto\_node\_role\_name](#output\_auto\_node\_role\_name) | ARN of the role associated specifically with auto-mode nodes |
| <a name="output_certificate_authority"></a> [certificate\_authority](#output\_certificate\_authority) | Certificate authority data for EKS control plane |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | URL of the EKS control plane endpoint |
| <a name="output_node_role_arns"></a> [node\_role\_arns](#output\_node\_role\_arns) | ARNs of all roles associated with roles |
| <a name="output_oidc_issuer"></a> [oidc\_issuer](#output\_oidc\_issuer) | OIDC URL to be provided to Relyance for cross-cloud access |
<!-- END_TF_DOCS -->
