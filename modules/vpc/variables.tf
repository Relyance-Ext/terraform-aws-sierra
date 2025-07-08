variable "base_name" {
  description = "Base name for VPC-related resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (should be at least /16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 65535))
    error_message = "Must be valid CIDR of at least 16 bits"
  }
}

variable "subnet_cidrs" {
  description = "Map of AZ to subnet CIDR blocks; one entry per availability zone"
  type        = map(string)

  validation {
    condition = alltrue([
      for _, cidr in var.subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDRs must be valid CIDR syntax"
  }
}

variable "nat_subnet_cidr" {
  description = "CIDR block for the public subnet used by the NAT gateway"
  type        = string

  validation {
    condition     = can(cidrhost(var.nat_subnet_cidr, 15))
    error_message = "Must be valid CIDR of at least 4 bits"
  }
}

variable "default_tags" {
  description = "Tags to be applied to all networking-related AWS resources"
  type        = map(string)
}
