# Use locals block to do validation
locals {
  cluster_name = data.aws_eks_cluster.main.name

  # auto mode (if required) needs multiple flags to be set true
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#eks-cluster-with-eks-auto-mode

  # Null-safe raw values from the EKS data source
  compute_config_enabled_raw = try(data.aws_eks_cluster.main.compute_config[0].enabled, null)
  elb_enabled_raw            = try(data.aws_eks_cluster.main.kubernetes_network_config[0].elastic_load_balancing[0].enabled, null)
  block_storage_enabled_raw  = try(data.aws_eks_cluster.main.storage_config[0].block_storage[0].enabled, null)

  # Ternaries that treat only "true" as enabled; false/null are both not enabled
  compute_config_enabled = (
    var.require_cluster_auto_mode ? (local.compute_config_enabled_raw == true) : false
  )

  elb_enabled = (
    var.require_cluster_auto_mode ? (local.elb_enabled_raw == true) : false
  )

  block_storage_enabled = (
    var.require_cluster_auto_mode ? (local.block_storage_enabled_raw == true) : false
  )

  # Relyance InHost requires the pod identity agent addon.
  # If the addon is missing the data source will probably fail to load at
  # plan time, but this will flag if it loads, but we get back weird data.
  pod_identity_agent = (
    var.require_cluster_addons ? can(data.aws_eks_addon.main["eks-pod-identity-agent"].addon_version) : false
  )

  # Message that safely prints null/booleans
  _auto_mode_error = <<EOT
Auto mode is required (require_existing_eks_cluster_auto_mode = true) but cluster "${local.cluster_name}" is missing one or more required settings:

- compute_config.enabled                                  = ${jsonencode(local.compute_config_enabled_raw)}
- kubernetes_network_config.elastic_load_balancing.enabled = ${jsonencode(local.elb_enabled_raw)}
- storage_config.block_storage.enabled                     = ${jsonencode(local.block_storage_enabled_raw)}

Set require_existing_eks_cluster_auto_mode = false if you have consulted with Relyance and are ready to deploy in a non-auto mode cluster.
EOT
}

resource "null_resource" "validate_existing_cluster" {
  lifecycle {
    # Auto-mode requirements: only when the flag is on
    precondition {
      condition = !var.require_cluster_auto_mode || alltrue([
        local.compute_config_enabled,
        local.elb_enabled,
        local.block_storage_enabled,
      ])
      error_message = local._auto_mode_error
    }

    # Addon requirement: only when the flag is on
    precondition {
      condition     = !var.require_cluster_addons || local.pod_identity_agent
      error_message = "eks-pod-identity-agent addon missing on cluster ${local.cluster_name}. Install it or set require_existing_eks_cluster_addons = false."
    }
  }
}
