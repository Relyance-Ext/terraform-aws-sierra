#
# resources created in Kubernetes using the Kubernetes API (not AWS)
#
locals {
  should_create_kubernetes_resources = var.create_vpc_and_eks && anytrue([
    var.enable_auto_mode_node_tags,
  ])

  will_create_kubernetes_resources = local.should_create_kubernetes_resources && var.create_kubernetes_resources
}

# Pseudo-resource to explain access to the EKS control plane and how to disable it temporarily.
resource "terraform_data" "explain_kube_access" {
  depends_on = [module.eks]
  count      = local.should_create_kubernetes_resources ? 1 : 0

  triggers_replace = {
    timestamp = timestamp()
  }
  provisioner "local-exec" {
    command = <<-END_COMMAND
      cat << END_MESSAGE
      In order to set up kubernetes resources, you must have access to the EKS control plane.
      You must also have permission to get EKS credential token using the 'aws' CLI.
      Without that, we cannot set up required node class and node pool resources for consistent node tagging.
      If you still need to set up private routing and get-token permission, you can temporarily set
        create_kubernetes_resources = false
      However, to complete setup, you need to gain access, then plan and apply with flag set to true.
      END_MESSAGE
    END_COMMAND
  }
}

# Depend on this to make explicit that control plane access must be established first.
data "http" "control_plane_access" {
  depends_on = [terraform_data.explain_kube_access]

  count              = local.will_create_kubernetes_resources ? 1 : 0
  url                = local.eks_cluster_endpoint
  insecure           = true # We're just verifying network connectivity
  request_timeout_ms = 5000 # Note: connect timeout is a minute, can't be overridden.

  lifecycle {
    postcondition {
      condition     = self.status_code == 401
      error_message = "Status code ${self.status_code} is not expected 401 (unauthenticated)"
    }
  }
}

provider "kubernetes" {
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = local.eks_cluster_ca_data

  exec {
    # Use the stable v1 API version
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name]
  }
}

module "node_pools" {
  source     = "./modules/node_pools"
  depends_on = [data.http.control_plane_access]
  count      = (var.enable_auto_mode_node_tags && local.will_create_kubernetes_resources) ? 1 : 0

  role_name    = module.eks[0].auto_node_role_name
  subnet_ids   = module.vpc[0].subnet_ids
  cluster_name = local.eks_cluster_name
  node_tags    = local.node_tags
}
