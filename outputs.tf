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

output "aws_account_id" {
  description = "AWS account ID where this module is deployed"
  value       = local.account_id
}

output "cluster_created_by_module" {
  description = "Whether the EKS cluster was created by this module (true) or an existing cluster was used (false)"
  value       = var.create_vpc_and_eks
}

output "eks_cluster_auto_mode" {
  description = "Whether the EKS cluster is running in auto mode. Always true for module-created clusters."
  value       = var.create_vpc_and_eks ? true : module.existing_eks[0].is_auto_mode
}

output "byok_secret_write_back" {
  description = "Whether the scanner role may write refreshed OAuth tokens back to BYOK secrets (var.byok_secret_write_back). Pass it to the deployment: Helm value byokSecretWriteBack, or env var SECRET_REF_WRITE_BACK (\"true\"/\"false\") in the kustomize package. The two must match: with false here and write-back on in the deployment, each write-back is denied and logged."
  value       = var.byok_secret_write_back
}
