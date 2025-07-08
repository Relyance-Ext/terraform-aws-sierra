variable "cluster_name" {
  description = "Name of existing EKS cluster"
  type        = string
}

variable "require_cluster_auto_mode" {
  description = "Set true to require that the existing cluster be in auto mode"
  type        = bool
}

variable "require_cluster_addons" {
  description = "Set true to require that the existing cluster have expected addons"
  type        = bool
}
