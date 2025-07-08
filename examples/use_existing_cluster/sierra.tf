# Single file with everything you need.
# For local consistency during updates, run
#     terraform init
#     terraform plan -out sierra.tfplan
#     terraform apply sierra.tfplan
# For collaboration, configure backend for shared remote state file
# For maintainability, replace hard-coded values with variables or outputs from other modules

module "sierra" {
  source = "Relyance-Ext/sierra/aws"

  env = "stage"

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
}

provider "aws" {}

output "sierra" {
  description = "Information to provide to Relyance"
  value       = module.sierra
}
