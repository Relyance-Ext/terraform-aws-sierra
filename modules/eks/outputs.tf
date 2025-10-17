output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "oidc_issuer" {
  description = "OIDC URL to be provided to Relyance for cross-cloud access"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "auto_node_role_name" {
  description = "ARN of the role associated specifically with auto-mode nodes"
  value       = aws_iam_role.node["auto"].name
}

output "node_role_arns" {
  description = "ARNs of all roles associated with roles"
  value       = [for node_role in aws_iam_role.node : node_role.arn]
}

output "endpoint" {
  description = "URL of the EKS control plane endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "certificate_authority" {
  description = "Certificate authority data for EKS control plane"
  value       = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
}
