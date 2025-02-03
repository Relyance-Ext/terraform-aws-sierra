variable "base_name" {
  description = "base name for all resources"
  type        = string
  default     = "Relyance_Sierra"
}

variable "env" {
  description = "What environment are you accessing [stage, prod]?"
  type        = string

  validation {
    condition     = contains(keys(local.per_env_s3_read_access_principals), var.env)
    error_message = "env must be 'stage' or 'prod'" # Note: keep in sync with the local dict.
  }
}

variable "policy" {
  description = "IAM policy ARN, if any, to bind to the Sierra application role"
  type        = string
  default     = null
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block (at least 16-bits large) for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 65535))
    error_message = "Must be valid CIDR of at least 16 bits"
  }
}

variable "service_cidr" {
  description = "CIDR block (at least 16-bits large) for EKS services"
  type        = string

  validation {
    condition     = can(cidrhost(var.service_cidr, 65535))
    error_message = "Must be valid CIDR of at least 16 bits"
  }
}

variable "subnet_cidrs" {
  description = "Map of AZ to CIDR block. Must have entry for every AZ in region"
  type        = map(string)
  validation {
    condition = alltrue([
      for _, cidr in var.subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid CIDR syntax"
  }
}

variable "nat_subnet_cidr" {
  description = "CIDR block for the outbound NAT's public subnet"
  validation {
    condition     = can(cidrhost(var.nat_subnet_cidr, 15))
    error_message = "Must be valid CIDR of at least 4 bits"
  }
}

# EKS
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

variable "ssh_key_pair" {
  description = "If set, allow SSH to EKS nodes using this pre-existing key pair"
  type        = string
  default     = null
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

