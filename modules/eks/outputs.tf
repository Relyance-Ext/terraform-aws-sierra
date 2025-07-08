output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "oidc_issuer" {
  description = "OIDC URL to be provided to Relyance for cross-cloud access"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_role_arns" {
  description = "ARNs of all roles associated with roles"
  value       = [for node_role in aws_iam_role.node : node_role.arn]
}