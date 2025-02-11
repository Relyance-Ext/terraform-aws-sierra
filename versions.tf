terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.79" # 5.79 introduces EKS auto mode support
    }
  }

  required_version = "~> 1.9"
}
