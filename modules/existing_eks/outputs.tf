output "cluster_name" {
  value = data.aws_eks_cluster.main.name
}

output "oidc_issuer" {
  description = "OIDC URL to be provided to Relyance for cross-cloud access"
  value       = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "endpoint" {
  description = "URL of the EKS control plane endpoint"
  value       = data.aws_eks_cluster.main.endpoint
}

output "certificate_authority" {
  description = "Certificate authority data for EKS control plane"
  value       = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
}
