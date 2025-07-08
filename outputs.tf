output "reader_external_id" {
  description = "External ID required to be passed for the STS assume-role"
  value       = random_uuid.reader_external_id.result
}

output "oidc_issuer" {
  description = "OIDC URL to be provided to Relyance for cross-cloud access"
  value       = local.eks_cluster_oidc_issuer
}
