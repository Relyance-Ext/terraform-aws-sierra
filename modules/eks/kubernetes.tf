# Kubernetes resources we only create if _also_ creating an EKS cluster

resource "aws_eks_access_entry" "admin" {
  for_each = var.eks_kubectl_admins

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = var.eks_kubectl_admins

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "cluster-admin" {
  for_each = var.eks_kubectl_admins

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }
}
