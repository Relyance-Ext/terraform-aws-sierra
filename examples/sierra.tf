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

output "sierra" {
  description = "Information to provide to Relyance"
  value       = module.sierra
}
