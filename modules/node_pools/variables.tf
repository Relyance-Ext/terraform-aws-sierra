variable "role_name" {
  type        = string
  description = "name of the role for custom-tagged auto mode nodes"
}

variable "cluster_name" {
  type        = string
  description = "name of the cluster for the node pool"
}

variable "subnet_ids" {
  type        = set(string)
  description = "subnets in which to create the nodes"
}

variable "node_tags" {
  type        = map(string)
  description = "tags to apply to the nodes"
}
