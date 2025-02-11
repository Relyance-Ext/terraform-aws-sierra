# Sierra Core Environment in AWS Terraform Module

## Introduction

This module is provided for use by customers of Relyance AI.
Visit [relyance.ai](https://relyance.ai) to learn more about our services.

## Usage

When you have agreed to sign up for Sierra,
this module will stand up infrastructure for core environment.
Init, plan, and apply the module, providing values:

* Subnet CIDR blocks compatible with your network
* CIDR blocks for CI/CD and administrative access
* Your environment ("stage" or "prod")

In order to be functional, you must

* Set up role in every data account which
  * can read S3 buckets and decrypt using those buckets' KMS keys, if any, and
  * can be assumed by the `Relyance_Sierra` role.
  * We will be providing an additional Terraform module to facilitate setup.
* Install Relyance Helm chart into the EKS cluster
  * This is still in active development; contact Relyance for support.

## Resources Created

All resources will have the tag `relyance-sierra` set to the module version.

* A VPC with subnets
* outbound NAT + internet gateway
* An EKS cluster `Relyance_Sierra` with node groups tuned for Sierra workloads
* S3 buckets
  * `relyance-work-<accountId>`: used internally
  * `relyance-findings-<accountId>`: accessible from Relyance environment
* KMS key for encrypting S3 buckets and EKS secrets

### IAM resources

The module creates 3 roles:

* `Relyance_Sierra`: Used by EKS nodes where Relyance's code will run
* `Relyance_Sierra_Cluster`: Used by the cluster itself
* `Relyance_Sierra_Reader`: Used by Relyance to read from findings bucket
  * This role has a trust policy allowing an env-specific identity to assume it.

In addition to permissions directly on module resources,
these roles are granted account-level permissions by attaching standard policies:

* `AmazonEKSWorkerNodePolicy`
* `AmazonEKS_CNI_Policy`
* `AmazonEC2ContainerRegistryReadOnly`
* `AmazonEKSClusterPolicy`

Finally, on order to scan, the `Relyance_Sierra` role is
granted `sts:AssumeRole` in accounts listed in `assumable_account_ids`
(or any account by setting `assume_all_roles` flag to true)

## Known limitations

* EKS access is only supported on public endpoint from allowed IPv4 CIDR blocks.

## Example

<!-- HCL below should be in sync with examples/sierra.tf -->
```hcl
# Single file with everything you need.
# For local consistency during updates, run
#     terraform init
#     terraform plan -out sierra.tfplan
#     terraform apply sierra.tfplan
# For collaboration, configure backend for shared remote state file
# For maintainability, replace hard-coded values with variables or outputs from other modules

module "sierra" {
  source  = "Relyance-Ext/sierra/aws"

  env = "stage"
  # Update these to match your AWS environment

  policy = null # Set this to grant additional permissions to the Sierra role

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

  ssh_key_pair = null # Set this for SSH access to the nodes to troubleshoot

  # The default value, true, makes Terraform applier a Kubernetes admin for later Helm deploy
  eks_make_terraform_deployer_admin = true
  # named IAM principal ARNs for additional admins
  eks_kubectl_admins = {}
}

provider "aws" {}
```

<!-- Everything below this line is output from terraform-docs tool -->

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
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_findings_bucket"></a> [findings\_bucket](#module\_findings\_bucket) | ./modules/s3 | n/a |
| <a name="module_work_bucket"></a> [work\_bucket](#module\_work\_bucket) | ./modules/s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_instance_connect_endpoint.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_instance_connect_endpoint) | resource |
| [aws_eip.main-nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eks_access_entry.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_access_policy_association.cluster-admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.kube-proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.pod-identity-agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc-cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_eks_pod_identity_association.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_role.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_kms_alias.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_launch_template.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.main-nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.nat-igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.nat-igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.eice](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.eice-egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eice-ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [random_uuid.reader_external_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [aws_availability_zones.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.main_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assumable_account_ids"></a> [assumable\_account\_ids](#input\_assumable\_account\_ids) | List of account IDs where resources can be assumed. | `list(string)` | `[]` | no |
| <a name="input_assume_all_roles"></a> [assume\_all\_roles](#input\_assume\_all\_roles) | Enable role assumption on all resources | `bool` | `false` | no |
| <a name="input_base_name"></a> [base\_name](#input\_base\_name) | base name for all resources | `string` | `"Relyance_Sierra"` | no |
| <a name="input_eks_kubectl_admins"></a> [eks\_kubectl\_admins](#input\_eks\_kubectl\_admins) | map of unique IDs to IAM identity ARNs to make admin + cluster admin | `map(string)` | `{}` | no |
| <a name="input_eks_make_terraform_deployer_admin"></a> [eks\_make\_terraform\_deployer\_admin](#input\_eks\_make\_terraform\_deployer\_admin) | If set, AWS identity performing Terraform deploy will gain kubectl access | `bool` | `true` | no |
| <a name="input_eks_public_access_cidrs"></a> [eks\_public\_access\_cidrs](#input\_eks\_public\_access\_cidrs) | Allow EKS control plane access from the internet? | `list(string)` | `[]` | no |
| <a name="input_eks_require_metadata_token"></a> [eks\_require\_metadata\_token](#input\_eks\_require\_metadata\_token) | If true, enforce more secure and modern IMDSv2 | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | What environment are you accessing [stage, prod]? | `string` | n/a | yes |
| <a name="input_nat_subnet_cidr"></a> [nat\_subnet\_cidr](#input\_nat\_subnet\_cidr) | CIDR block for the outbound NAT's public subnet | `any` | n/a | yes |
| <a name="input_policy"></a> [policy](#input\_policy) | IAM policy ARN, if any, to bind to the Sierra application role | `string` | `null` | no |
| <a name="input_s3_bucket_suffix"></a> [s3\_bucket\_suffix](#input\_s3\_bucket\_suffix) | Suffix to add to bucket name to avoid (unexpected) collision. Contact Relyance if set | `string` | `""` | no |
| <a name="input_s3_expiration_days"></a> [s3\_expiration\_days](#input\_s3\_expiration\_days) | Number of days before objects in S3 findings bucket expire | `number` | `180` | no |
| <a name="input_s3_read_access_principals"></a> [s3\_read\_access\_principals](#input\_s3\_read\_access\_principals) | Supplemental list of role/user ARNs for read access to the findings bucket | `list(string)` | `[]` | no |
| <a name="input_s3_use_bucket_keys"></a> [s3\_use\_bucket\_keys](#input\_s3\_use\_bucket\_keys) | Enable bucket keys to reduce KMS costs in the S3 findings bucket | `bool` | `true` | no |
| <a name="input_s3_workspace_expiration_days"></a> [s3\_workspace\_expiration\_days](#input\_s3\_workspace\_expiration\_days) | Number of days before objects in S3 workspace bucket expire | `number` | `7` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | CIDR block (at least 16-bits large) for EKS services | `string` | n/a | yes |
| <a name="input_ssh_key_pair"></a> [ssh\_key\_pair](#input\_ssh\_key\_pair) | If set, allow SSH to EKS nodes using this pre-existing key pair | `string` | `null` | no |
| <a name="input_subnet_cidrs"></a> [subnet\_cidrs](#input\_subnet\_cidrs) | Map of AZ to CIDR block. Must have entry for every AZ in region | `map(string)` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block (at least 16-bits large) for VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_oidc_issuer"></a> [oidc\_issuer](#output\_oidc\_issuer) | OIDC URL to be provided to Relyance for cross-cloud access |
| <a name="output_reader_external_id"></a> [reader\_external\_id](#output\_reader\_external\_id) | External ID required to be passed for the STS assume-role |
<!-- END_TF_DOCS -->
