# InHost Core Environment in AWS Terraform Module

## Introduction

This module is provided for use by customers of Relyance AI.
Visit [relyance.ai](https://relyance.ai) to learn more about our services.

## Usage

When you have agreed to sign up for InHost,
this module will stand up infrastructure for core environment.
Init, plan, and apply the module, providing values:

* Subnet CIDR blocks compatible with your network
* CIDR blocks for CI/CD and administrative access

In order to be functional, you must

* Set up role in every data account which
  * can read S3 buckets and decrypt using those buckets' KMS keys, if any, and
  * can be assumed by the `Relyance_Sierra` role.
  * We will be providing an additional Terraform module to facilitate setup.
* Install Relyance Helm chart into the EKS cluster
  * This is still in active development; contact Relyance for support.

### Resources Created

InHost development codename "Sierra" is still in use for cloud resources.

All resources will have the tag `relyance-sierra` set to the module version.

* A VPC with subnets
* outbound NAT + internet gateway
* An EKS cluster `Relyance_Sierra` with node groups tuned for Sierra workloads
* S3 buckets
  * `relyance-work-<accountId>`: used internally
  * `relyance-findings-<accountId>`: accessible from Relyance environment
* KMS key for encrypting S3 buckets and EKS secrets

#### IAM resources

The module creates 3 roles:

* `Relyance_Sierra`: Used by Kubernetes pods where Relyance's code will run
* `Relyance_Sierra_Reader`: Used by Relyance to read from findings bucket
  * This role has a trust policy allowing an env-specific identity to assume it.
* `Reyance_Sierra_Node` and `Relyance_Sierra_Auto` for EKS nodes
* `Relyance_Sierra_Cluster`: Used by the cluster itself

In addition to permissions directly on module resources,
these roles are granted account-level permissions by attaching standard policies:

* `AmazonEKSWorkerNodePolicy`
* `AmazonEKS_CNI_Policy`
* `AmazonEC2ContainerRegistryReadOnly`
* `AmazonEKSClusterPolicy`

Finally, on order to scan, the `Relyance_Sierra` role is
granted `sts:AssumeRole` in accounts listed in `assumable_account_ids`
(or any account by setting `assume_all_roles` flag to true)

#### Auto-mode Node Tags

By default, AWS auto mode does not let you apply tags to nodes created by auto mode.
If your AWS tag policy requires that nodes have certain tags to be created, and/or
if a cleanup process will remove any nodes without those tags, additional steps are
required to set up alternative node class and node pools.

* Set all required tags into the `default_tags` variable
* Set the `enable_auto_mode_node_tags` flag to true
* Ensure that you have sufficient privileges to run `aws eks get-token` on the new cluster
  * `eks_make_terraform_deployer_admin`, which defaults true, should guarantee this access.
* Ensure that you have a network route to the control plane
  * Add CIDR containing your current public address (or VPN egress address) to `eks_public_access_cidrs`
  * If you want to use internal connectivity,
    * plan and apply first with `create_kubernetes_resources = false`,
    * establish network route and private DNS to the cluster's private control plane, and
    * plan and apply again with `create_kubernetes_resources` removed (default is `true`).
* Ensure that all InHost pods run on the custom nodeclass `relyance-inhost`
  * In Relyance-provided Helm, set `aws.nodeclass: relyance-sierra` in your tenant-specific values file.

### Alternate mode: use existing EKS cluster

By setting
* `create_vpc_and_eks = false`
* `existing_eks_cluster_name = "Customer-Cluster"`

you can deploy Relyance InHost into your existing Auto Mode EKS cluster.
In this mode, the Terraform module only creates
* S3 buckets
* KMS key (used only for S3 bucket encryption)
* `Relyance_Sierra` and `Relyance_Sierra_Reader` roles and associated policies

## Known limitations

* EKS access is only supported on public endpoint from allowed IPv4 CIDR blocks.

## Examples

### Full stack creation

<!-- HCL below should be in sync with examples/create_cluster/sierra.tf -->
```hcl
# Single file with everything you need.
# For local consistency during updates, run
#     terraform init
#     terraform plan -out sierra.tfplan
#     terraform apply sierra.tfplan
# For collaboration, configure backend for shared remote state file
# For maintainability, replace hard-coded values with variables or outputs from other modules

module "sierra" {
  source = "Relyance-Ext/sierra/aws"

  # The GCP project where findings data is captured
  # To be provided by Relyance; required if code_analysis_enabled is true
  gcp_project = "example-project"

  # Update these to match your AWS environment

  # Networking: Pick ranges which don't conflict with your existing environment.
  vpc_cidr     = "172.30.0.0/16"
  service_cidr = "10.100.0.0/16"

  subnet_cidrs = {
    usw2-az1 = "172.30.0.0/20"
    usw2-az2 = "172.30.16.0/20"
    usw2-az3 = "172.30.32.0/20"
    usw2-az4 = "172.30.48.0/20"
  }

  nat_subnet_cidr = "172.30.255.0/24" # Maybe overkill for a single NAT

  # EKS
  eks_public_access_cidrs = [
    # Include at least one CI/CD, admin env, developer VPN, etc.
  ]

  # Cross-account scan access
  assumable_account_ids = [] # You must set at least one account ID, or set flag `assume_all_roles`

  # The default value, true, makes Terraform applier a Kubernetes admin for later Helm deploy
  eks_make_terraform_deployer_admin = true
  # named IAM principal ARNs for additional admins
  eks_kubectl_admins = {}

  # Enable Code Analyzer support
  code_analysis_enabled = false

  # Give bucket read access to additional principals for diagnostics and troubleshooting
  s3_read_access_principals = []

  # Tags to apply in all resources (e.g. for compliance with organization tag policy)
  default_tags = {
    # key = value
  }

  # If your org enforces tag policy, set true to support auto mode nodes with default_tags applied
  enable_auto_mode_node_tags = false
}

provider "aws" {
  default_tags {
    # Set tags in var.default_tags to add to all resources, including dynamically-created.
    tags = module.sierra.default_tags
  }
}

output "sierra" {
  description = "Information to provide to Relyance"
  value       = module.sierra
}
```

### Reuse existing EKS cluster

Create S3 buckets, KMS key, and IAM identities for use with an existing cluster.
Remember, the cluster should be auto mode, with EKS pod identity agent addon installed.
<!-- HCL below should be in sync with examples/use_existing_cluster/sierra.tf -->
```hcl
# Single file with everything you need.
# For local consistency during updates, run
#     terraform init
#     terraform plan -out sierra.tfplan
#     terraform apply sierra.tfplan
# For collaboration, configure backend for shared remote state file
# For maintainability, replace hard-coded values with variables or outputs from other modules

module "sierra" {
  source = "Relyance-Ext/sierra/aws"

  # Update these to match your AWS environment
  create_vpc_and_eks = false
  # Expects auto mode cluster with eks-pod-identity-agent addon installed
  existing_eks_cluster_name = "Customer-Cluster"

  # Cross-account scan access
  assumable_account_ids = [] # You must set at least one account ID, or set flag `assume_all_roles`

  # Enable Code Analyzer support
  code_analysis_enabled = false

  # Give bucket read access to additional principals for diagnostics and troubleshooting
  s3_read_access_principals = []

  # Tags to apply in all resources (e.g. for compliance with organization tag policy)
  default_tags = {
    # key = value
  }
}

provider "aws" {
  default_tags {
    # Set tags in var.default_tags to add to all resources, including dynamically-created.
    tags = module.sierra.default_tags
  }
}

output "sierra" {
  description = "Information to provide to Relyance"
  value       = module.sierra
}
```

<!-- Everything below this line is output from terraform-docs markdown table -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.79 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.79 |
| <a name="provider_http"></a> [http](#provider\_http) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks | n/a |
| <a name="module_existing_eks"></a> [existing\_eks](#module\_existing\_eks) | ./modules/existing_eks | n/a |
| <a name="module_findings_bucket"></a> [findings\_bucket](#module\_findings\_bucket) | ./modules/s3 | n/a |
| <a name="module_node_pools"></a> [node\_pools](#module\_node\_pools) | ./modules/node_pools | n/a |
| <a name="module_sci_bucket"></a> [sci\_bucket](#module\_sci\_bucket) | ./modules/s3 | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |
| <a name="module_work_bucket"></a> [work\_bucket](#module\_work\_bucket) | ./modules/s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eks_pod_identity_association.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.sci](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_alias.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [random_uuid.reader_external_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [terraform_data.explain_kube_access](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.main_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sci_assume_role_with_web_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |
| [http_http.control_plane_access](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assumable_account_ids"></a> [assumable\_account\_ids](#input\_assumable\_account\_ids) | List of account IDs where resources can be assumed. | `list(string)` | `[]` | no |
| <a name="input_assume_all_roles"></a> [assume\_all\_roles](#input\_assume\_all\_roles) | Enable role assumption on all resources | `bool` | `false` | no |
| <a name="input_base_name"></a> [base\_name](#input\_base\_name) | base name for all resources | `string` | `"Relyance_Sierra"` | no |
| <a name="input_code_analysis_enabled"></a> [code\_analysis\_enabled](#input\_code\_analysis\_enabled) | Create related resources and set up cross-cloud role assumption for the Code Analyzer | `bool` | `false` | no |
| <a name="input_create_kubernetes_resources"></a> [create\_kubernetes\_resources](#input\_create\_kubernetes\_resources) | Set false to skip Kubernetes resource creation until you can establish network access to EKS control plane and AWS auth | `bool` | `true` | no |
| <a name="input_create_vpc_and_eks"></a> [create\_vpc\_and\_eks](#input\_create\_vpc\_and\_eks) | If false, assumes external VPC and EKS exist and skips their creation | `bool` | `true` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Tags to apply to all AWS resources. Use instead of setting on aws provider to apply to dynamic resources. | `map(string)` | `{}` | no |
| <a name="input_eks_kubectl_admins"></a> [eks\_kubectl\_admins](#input\_eks\_kubectl\_admins) | map of unique IDs to IAM identity ARNs to make admin + cluster admin | `map(string)` | `{}` | no |
| <a name="input_eks_make_terraform_deployer_admin"></a> [eks\_make\_terraform\_deployer\_admin](#input\_eks\_make\_terraform\_deployer\_admin) | If set, AWS identity performing Terraform deploy will gain kubectl access | `bool` | `true` | no |
| <a name="input_eks_public_access_cidrs"></a> [eks\_public\_access\_cidrs](#input\_eks\_public\_access\_cidrs) | Allow EKS control plane access from the internet? | `list(string)` | `[]` | no |
| <a name="input_eks_require_metadata_token"></a> [eks\_require\_metadata\_token](#input\_eks\_require\_metadata\_token) | If true, enforce more secure and modern IMDSv2 | `bool` | `true` | no |
| <a name="input_enable_auto_mode_node_tags"></a> [enable\_auto\_mode\_node\_tags](#input\_enable\_auto\_mode\_node\_tags) | Set true to apply default\_tags to auto mode nodes | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | What environment are you accessing [stage, prod]? | `string` | `"prod"` | no |
| <a name="input_existing_eks_cluster_name"></a> [existing\_eks\_cluster\_name](#input\_existing\_eks\_cluster\_name) | Name of existing EKS cluster to use when create\_vpc\_and\_eks is false | `string` | `null` | no |
| <a name="input_gcp_project"></a> [gcp\_project](#input\_gcp\_project) | The GCP project name in Relyance used to facilitate cross-cloud communication | `string` | `null` | no |
| <a name="input_nat_subnet_cidr"></a> [nat\_subnet\_cidr](#input\_nat\_subnet\_cidr) | CIDR block for the outbound NAT's public subnet | `string` | `""` | no |
| <a name="input_override_service_account"></a> [override\_service\_account](#input\_override\_service\_account) | Override service account name used for pod identity (testing only – do not use in production) | `string` | `null` | no |
| <a name="input_require_existing_eks_cluster_addons"></a> [require\_existing\_eks\_cluster\_addons](#input\_require\_existing\_eks\_cluster\_addons) | Set false to allow existing EKS cluster without expected addons | `bool` | `true` | no |
| <a name="input_require_existing_eks_cluster_auto_mode"></a> [require\_existing\_eks\_cluster\_auto\_mode](#input\_require\_existing\_eks\_cluster\_auto\_mode) | Set false to allow existing EKS cluster not in auto mode | `bool` | `true` | no |
| <a name="input_s3_bucket_suffix"></a> [s3\_bucket\_suffix](#input\_s3\_bucket\_suffix) | Suffix to add to bucket name to avoid (unexpected) collision. Contact Relyance if set | `string` | `""` | no |
| <a name="input_s3_expiration_days"></a> [s3\_expiration\_days](#input\_s3\_expiration\_days) | Number of days before objects in S3 findings bucket expire | `number` | `180` | no |
| <a name="input_s3_read_access_principals"></a> [s3\_read\_access\_principals](#input\_s3\_read\_access\_principals) | Supplemental list of role/user ARNs for read access to the findings bucket | `list(string)` | `[]` | no |
| <a name="input_s3_use_bucket_keys"></a> [s3\_use\_bucket\_keys](#input\_s3\_use\_bucket\_keys) | Enable bucket keys to reduce KMS costs in the S3 findings bucket | `bool` | `true` | no |
| <a name="input_s3_workspace_expiration_days"></a> [s3\_workspace\_expiration\_days](#input\_s3\_workspace\_expiration\_days) | Number of days before objects in S3 workspace bucket expire | `number` | `7` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | CIDR block (at least 16-bits large) for EKS services (null for default autoassign) | `string` | `""` | no |
| <a name="input_subnet_cidrs"></a> [subnet\_cidrs](#input\_subnet\_cidrs) | Map of AZ to CIDR block. Must have entry for every AZ in region | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block (at least 16-bits large) for VPC | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_tags"></a> [default\_tags](#output\_default\_tags) | Tags to be applied to all resources |
| <a name="output_enable_auto_mode_node_tags"></a> [enable\_auto\_mode\_node\_tags](#output\_enable\_auto\_mode\_node\_tags) | Is there support for auto mode nodes with custom tags? |
| <a name="output_oidc_issuer"></a> [oidc\_issuer](#output\_oidc\_issuer) | OIDC URL to be provided to Relyance for cross-cloud access |
| <a name="output_reader_external_id"></a> [reader\_external\_id](#output\_reader\_external\_id) | External ID required to be passed for the STS assume-role |
<!-- END_TF_DOCS -->
