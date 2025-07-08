output "cluster_name" {
  value = data.aws_eks_cluster.main.name
}

output "oidc_issuer" {
  description = "OIDC URL to be provided to Relyance for cross-cloud access"
  value       = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
}
