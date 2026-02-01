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
