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
  description = "CIDR block for the public subnets used by NAT gateways (will be split into two equal-size subnets; must be /27 or larger so result is at least /28)"
  type        = string

  validation {
    condition     = can(cidrhost(var.nat_subnet_cidr, 0))
    error_message = "nat_subnet_cidr must be a valid IPv4 CIDR (e.g., 10.0.100.0/27)."
  }

  validation {
    condition = (
      can(regex("/(\\d+)$", var.nat_subnet_cidr)) &&
      tonumber(regex("/(\\d+)$", var.nat_subnet_cidr)[0]) <= 27
    )
    error_message = "nat_subnet_cidr must have prefix length <= 27 so splitting into two equal subnets results in subnets no smaller than /28 (AWS minimum subnet size)."
  }
}

variable "default_tags" {
  description = "Tags to be applied to all networking-related AWS resources"
  type        = map(string)
}
