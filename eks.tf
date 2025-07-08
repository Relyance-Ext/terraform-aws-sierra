module "eks" {
  source = "./modules/eks"
  count  = var.create_vpc_and_eks ? 1 : 0

  base_name                  = var.base_name
  subnet_ids                 = module.vpc[0].subnet_ids
  service_cidr               = var.service_cidr
  eks_public_access_cidrs    = var.eks_public_access_cidrs
  eks_require_metadata_token = var.eks_require_metadata_token
  kms_key_arn                = aws_kms_key.main.arn
  eks_kubectl_admins = merge(
    var.eks_kubectl_admins,
    (
      var.eks_make_terraform_deployer_admin
      ? { "deployer" : data.aws_iam_session_context.current.issuer_arn }
      : {}
    )
  )
  default_tags = local.default_tags
}

module "existing_eks" {
  source = "./modules/existing_eks"
  count  = var.create_vpc_and_eks ? 0 : 1

  cluster_name              = var.existing_eks_cluster_name
  require_cluster_auto_mode = var.require_existing_eks_cluster_auto_mode
  require_cluster_addons    = var.require_existing_eks_cluster_addons
}

locals {
  eks_cluster_module = (
    var.create_vpc_and_eks ? module.eks[0] : module.existing_eks[0]
  )
  # Both modules have the same 2 outputs extracted below (implicit interface)
  eks_cluster_name        = local.eks_cluster_module.cluster_name
  eks_cluster_oidc_issuer = local.eks_cluster_module.oidc_issuer
}
