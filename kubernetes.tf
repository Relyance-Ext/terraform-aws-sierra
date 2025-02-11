# Kubernetes-specific settings
locals {
  # Service accounts which will assume the main role
  kube_service_accounts = {
    sierra = {
      ns = "sierra"
      sa = "relyance"
    }
  }

  kube_admin_arns = merge(
    var.eks_kubectl_admins,
    (
      var.eks_make_terraform_deployer_admin
      ? { "deployer" : data.aws_iam_session_context.current.issuer_arn }
      : {}
    )
  )
}

resource "aws_eks_pod_identity_association" "main" {
  for_each = local.kube_service_accounts

  cluster_name    = aws_eks_cluster.main.name
  namespace       = each.value.ns
  service_account = each.value.sa
  role_arn        = aws_iam_role.main.arn

  depends_on = [aws_eks_addon.pod-identity-agent]
}

resource "aws_eks_access_entry" "admin" {
  for_each = local.kube_admin_arns

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = local.kube_admin_arns

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "cluster-admin" {
  for_each = local.kube_admin_arns

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }
}
