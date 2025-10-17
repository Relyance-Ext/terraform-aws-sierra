output "default_tags" {
  description = "Tags to be applied to all resources"
  value       = local.default_tags
}

output "reader_external_id" {
  description = "External ID required to be passed for the STS assume-role"
  value       = random_uuid.reader_external_id.result
}

output "oidc_issuer" {
  description = "OIDC URL to be provided to Relyance for cross-cloud access"
  value       = local.eks_cluster_oidc_issuer
}

output "enable_auto_mode_node_tags" {
  description = "Is there support for auto mode nodes with custom tags?"
  value       = var.enable_auto_mode_node_tags
}
