terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.79, < 7.0" # 5.79 introduces EKS auto mode support; retain v5 and v6 compatibility
    }
  }

  required_version = "~> 1.9"
}
