variable "base_name" {
  description = "base name for all resources"
  type        = string
  default     = "Relyance_Sierra"
}

variable "env" {
  description = "What environment are you accessing [stage, prod]?"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(keys(local.per_env_s3_read_access_principals), var.env)
    error_message = "env must be 'stage' or 'prod'" # Note: keep in sync with the local dict.
  }
}

variable "default_tags" {
  description = "Tags to apply to all AWS resources. Use instead of setting on aws provider to apply to dynamic resources."
  type        = map(string)
  default     = {}

  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions
  # Limit key length
  validation {
    condition = alltrue([
      for k in keys(var.default_tags) : (length(k) <= 128)
    ])
    error_message = "keys must be no longer than 128 characters"
  }

  # Restrict characters
  validation {
    condition = alltrue([
      for k in keys(var.default_tags) : (length(regexall("^[A-Za-z0-9+\\-=\\._:/@]+$", k)) == 1)
    ])
    error_message = "keys must only have alphanumeric or one of: + - = . _ : @"
  }

  # Block reserved tags
  validation {
    condition = alltrue(flatten([
      for k in keys(var.default_tags) : [
        for prefix in local.reserved_tag_prefixes : !startswith(k, prefix)
      ]
    ]))
    error_message = "Tag mustn't start with AWS-reserved prefix"
  }

  # Restrict total number of tags (50 is maximum, but reserve room for Relyance/EKS tags)
  validation {
    condition     = length(var.default_tags) <= 30
    error_message = "Maximum of 30 customer-provided tags supported"
  }
}

variable "gcp_project" {
  description = "The GCP project name in Relyance used to facilitate cross-cloud communication"
  type        = string
  default     = null

  validation {
    condition     = !(var.code_analysis_enabled && var.gcp_project == null)
    error_message = "gcp_project is required if code_analysis_enabled is true"
  }
}

# ## Big switch: Do we create resources, or reuse existing ones?
variable "create_vpc_and_eks" {
  description = "If false, assumes external VPC and EKS exist and skips their creation"
  type        = bool
  default     = true
}

variable "existing_eks_cluster_name" {
  description = "Name of existing EKS cluster to use when create_vpc_and_eks is false"
  type        = string
  default     = null

  validation {
    condition     = !(!var.create_vpc_and_eks && var.existing_eks_cluster_name == null)
    error_message = "existing_eks_cluster_name is required if create_vpc_and_eks is false"
  }
}

variable "require_existing_eks_cluster_auto_mode" {
  description = "Set false to allow existing EKS cluster not in auto mode"
  type        = bool
  default     = true
}

variable "require_existing_eks_cluster_addons" {
  description = "Set false to allow existing EKS cluster without expected addons"
  type        = bool
  default     = true
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block (at least 16-bits large) for VPC"
  type        = string
  default     = ""
}

variable "subnet_cidrs" {
  description = "Map of AZ to CIDR block. Must have entry for every AZ in region"
  type        = map(string)
  default     = {}
}

variable "nat_subnet_cidr" {
  description = "CIDR block for the outbound NAT's public subnet"
  type        = string
  default     = ""
}

# EKS
variable "service_cidr" {
  description = "CIDR block (at least 16-bits large) for EKS services (null for default autoassign)"
  type        = string
  default     = ""
}

variable "eks_public_access_cidrs" {
  description = "Allow EKS control plane access from the internet?"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for cidr in var.eks_public_access_cidrs :
      (can(cidrhost(cidr, 0)) && !can(cidrhost(cidr, 65536)))
    ])
    error_message = "Each entry must be valid CIDR of no more than 16 bits in size"
  }
}

variable "eks_require_metadata_token" {
  description = "If true, enforce more secure and modern IMDSv2"
  type        = bool
  default     = true
}

variable "eks_make_terraform_deployer_admin" {
  description = "If set, AWS identity performing Terraform deploy will gain kubectl access"
  type        = bool
  default     = true
}

variable "eks_kubectl_admins" {
  description = "map of unique IDs to IAM identity ARNs to make admin + cluster admin"
  type        = map(string)
  default     = {}

  validation {
    condition     = !contains(keys(var.eks_kubectl_admins), "deployer")
    error_message = "'deployer' is reserved for the identity which deploys terraform"
  }
}

variable "enable_auto_mode_node_tags" {
  description = "Set true to apply default_tags to auto mode nodes"
  type        = bool
  default     = false
}

variable "create_kubernetes_resources" {
  description = "Set false to skip Kubernetes resource creation until you can establish network access to EKS control plane and AWS auth"
  type        = bool
  default     = true
}

# S3

variable "s3_bucket_suffix" {
  description = "Suffix to add to bucket name to avoid (unexpected) collision. Contact Relyance if set"
  type        = string
  default     = ""
}

variable "s3_expiration_days" {
  description = "Number of days before objects in S3 findings bucket expire"
  type        = number
  default     = 180
}

variable "s3_workspace_expiration_days" {
  description = "Number of days before objects in S3 workspace bucket expire"
  type        = number
  default     = 7
}

variable "s3_use_bucket_keys" {
  description = "Enable bucket keys to reduce KMS costs in the S3 findings bucket"
  type        = bool
  default     = true
}

variable "s3_read_access_principals" {
  description = "Supplemental list of role/user ARNs for read access to the findings bucket"
  type        = list(string)
  default     = []
}

# Outbound STS
variable "assumable_account_ids" {
  description = "List of account IDs where resources can be assumed."
  type        = list(string)
  default     = []
}

variable "assume_all_roles" {
  description = "Enable role assumption on all resources"
  type        = bool
  default     = false

  validation {
    condition     = !(length(var.assumable_account_ids) == 0 && var.assume_all_roles == false)
    error_message = "Must provide assumable_account_ids or assume_all_roles."
  }

  validation {
    condition     = !(length(var.assumable_account_ids) > 0 && var.assume_all_roles == true)
    error_message = "The assumable_account_ids and assume_all_roles variables are mutually exclusive."
  }
}

variable "code_analysis_enabled" {
  description = "Create related resources and set up cross-cloud role assumption for the Code Analyzer"
  type        = bool
  default     = false
}

## Test only

variable "override_service_account" {
  description = "Override service account name used for pod identity (testing only – do not use in production)"
  type        = string
  default     = null

  validation {
    condition     = !(var.env == "prod" && var.override_service_account != null)
    error_message = "override_serivce_account is only for testing and cannot be used in prod environment"
  }
}
