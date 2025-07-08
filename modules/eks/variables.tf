variable "base_name" {
  description = "Base name used to name EKS cluster and related resources (e.g., IAM roles)"
}

variable "subnet_ids" {
  description = "List of subnet IDs where EKS worker nodes should be launched"
  type        = list(string)
}

variable "eks_public_access_cidrs" {
  description = "List of CIDR blocks that are allowed to access the EKS control plane publicly"
  type        = list(string)
}

variable "eks_require_metadata_token" {
  description = "Whether to enforce use of IMDSv2 on EC2 nodes for improved security"
  type        = bool
  default     = true
}

variable "eks_kubectl_admins" {
  description = "Map of custom IAM principal ARNs to be granted kubectl admin access on the EKS cluster"
  type        = map(string)
}

variable "service_cidr" {
  description = "CIDR block (at least 16-bits large) for EKS services (null for default autoassign)"
  type        = string

  validation {
    condition     = var.service_cidr == null || can(cidrhost(var.service_cidr, 65535))
    error_message = "If not null, must be valid CIDR of at least 16 bits"
  }
}

variable "kms_key_arn" {
  description = "ARN of KMS symmetric key to encrypt Kubernetes secrets"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all AWS resources created in this module"
  type        = map(string)
}
