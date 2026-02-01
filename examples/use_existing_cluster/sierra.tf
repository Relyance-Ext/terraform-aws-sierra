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
  # gcp_project = "example-project"

  # Update these to match your AWS environment
  create_vpc_and_eks = false
  # Supports both auto mode and standard mode clusters with eks-pod-identity-agent addon installed
  # Set to true if using an auto mode cluster
  require_existing_eks_cluster_auto_mode = false
  existing_eks_cluster_name              = "Customer-Cluster"

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
