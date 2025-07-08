data "aws_eks_cluster" "main" {
  name = var.cluster_name
}

# Relyance has tested InHost with expected EKS add-ons.
# If plan or apply fails because add-ons are missing, but you're
# confident that your system is ready anyway, set flag
#     require_existing_eks_cluster_addons = false
# Unfortunately there's no "list addons for cluster" data source
data "aws_eks_addon" "main" {
  for_each = toset(var.require_cluster_addons ? [
    "eks-pod-identity-agent",
  ] : [])
  cluster_name = data.aws_eks_cluster.main.name
  addon_name   = each.value
}