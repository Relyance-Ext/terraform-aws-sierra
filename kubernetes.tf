# Kubernetes-specific settings (whether or not we create an EKS cluster)
locals {
  # Service accounts which will assume the main role
  kube_service_accounts = {
    sierra = {
      ns = "sierra"
      sa = coalesce(var.override_service_account, "relyance")
    }
  }
}

# NOTE: there is no data source, so if you're connecting to existing EKS cluster,
# it's on you to ensure that an association doesn't already exist for the service account.
resource "aws_eks_pod_identity_association" "main" {
  for_each = local.kube_service_accounts

  cluster_name    = local.eks_cluster_name
  namespace       = each.value.ns
  service_account = each.value.sa
  role_arn        = aws_iam_role.main.arn
}
