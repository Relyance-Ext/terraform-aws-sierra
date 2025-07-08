# Use locals block to do validation
# throw() is undefined, but gives us equivalent of an exception
# If condition is met, then plan fails and message is dumped to console.
locals {
  cluster_name = data.aws_eks_cluster.main.name

  req_true = <<-EOM
    Flag for cluster ${local.cluster_name} must be true for auto mode. Or set
        require_existing_eks_cluster_auto_mode = false
    if you have consulted with Relyance and are ready to deploy in non-auto mode cluster.
  EOM

  # auto mode (if required) needs multiple flags to be set true
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#eks-cluster-with-eks-auto-mode
  compute_config_enabled = (
    var.require_cluster_auto_mode
    ? (
      data.aws_eks_cluster.main.compute_config[0].enabled
      ? true
      : throw("compute_config.enabled false", local.req_true)
    ) : false
  )

  elb_enabled = (
    var.require_cluster_auto_mode
    ? (
      data.aws_eks_cluster.main.kubernetes_network_config[0].elastic_load_balancing[0].enabled
      ? true
      : throw("kubernetes_network_config.elastic_load_balancing.enabled false", local.req_true)
    ) : false
  )

  block_storage_enabled = (
    var.require_cluster_auto_mode
    ? (
      data.aws_eks_cluster.main.storage_config[0].block_storage[0].enabled
      ? true
      : throw("storage_config.block_storage.enabled false", local.req_true)
    ) : false
  )

  # Relyance InHost requires the pod identity agent addon.
  # If the addon is missing the data source will probably fail to load at
  # plan time, but this will flag if it loads, but we get back weird data.
  pod_identity_agent = (
    var.require_cluster_addons ?
    (
      can(data.aws_eks_addon.main["eks-pod-identity-agent"].addon_version)
      ? true
      : throw(
        <<-EOM
          eks-pod-identity-agent addon missing from cluster ${local.cluster_name}
          it must be installed, or set require_existing_eks_cluster_addons = false
        EOM
      )
    ) : false
  )
}
