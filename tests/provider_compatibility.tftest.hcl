# No AWS/Kubernetes/HTTP calls: these plans exercise both EKS branches with mocks.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { name = "us-west-2" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333", arn = "arn:aws:iam::111122223333:user/deployer" }
  }
  mock_data "aws_iam_session_context" {
    defaults = { issuer_arn = "arn:aws:iam::111122223333:user/deployer" }
  }
  mock_data "aws_availability_zones" {
    defaults = { zone_ids = ["usw2-az1", "usw2-az2"] }
  }
  mock_data "aws_eks_cluster" {
    defaults = {
      name                      = "fixture-cluster"
      endpoint                  = "https://example.invalid"
      identity                  = [{ oidc = [{ issuer = "https://oidc.example.invalid" }] }]
      certificate_authority     = [{ data = "Zm9v" }]
      compute_config            = [{ enabled = true }]
      kubernetes_network_config = [{ elastic_load_balancing = [{ enabled = true }] }]
      storage_config            = [{ block_storage = [{ enabled = true }] }]
    }
  }
  mock_data "aws_eks_addon" {
    defaults = { addon_version = "v1.3.4-eksbuild.1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111122223333:role/fixture-scanner" }
  }
}
mock_provider "http" {}
mock_provider "random" {}
mock_provider "kubernetes" {}

variables {
  assumable_account_ids = ["444455556666"]
}

run "existing_standard_cluster" {
  command = plan
  variables {
    create_vpc_and_eks                     = false
    existing_eks_cluster_name              = "fixture-cluster"
    require_existing_eks_cluster_auto_mode = false
  }
  override_data {
    target = module.existing_eks[0].data.aws_eks_cluster.main
    values = {
      name                      = "fixture-cluster"
      endpoint                  = "https://example.invalid"
      identity                  = [{ oidc = [{ issuer = "https://oidc.example.invalid" }] }]
      certificate_authority     = [{ data = "Zm9v" }]
      compute_config            = []
      kubernetes_network_config = []
      storage_config            = []
    }
  }
  assert {
    condition     = !output.cluster_created_by_module && !output.eks_cluster_auto_mode
    error_message = "Existing standard clusters must retain their mode and avoid cluster creation."
  }
  assert {
    condition     = length(module.eks) == 0 && length(module.vpc) == 0 && length(module.existing_eks) == 1
    error_message = "The existing-cluster path must not create EKS or VPC modules."
  }
  assert {
    condition     = aws_eks_pod_identity_association.main["sierra"].cluster_name == "fixture-cluster"
    error_message = "Pod identity must target the existing cluster."
  }
}

run "existing_auto_mode_cluster" {
  command = plan
  variables {
    create_vpc_and_eks        = false
    existing_eks_cluster_name = "fixture-cluster"
  }
  assert {
    condition     = !output.cluster_created_by_module && output.eks_cluster_auto_mode
    error_message = "Existing auto mode clusters must satisfy the default auto mode validation."
  }
}

run "create_cluster_defaults" {
  command = plan
  variables {
    vpc_cidr        = "172.30.0.0/16"
    service_cidr    = "10.100.0.0/16"
    subnet_cidrs    = { usw2-az1 = "172.30.0.0/20", usw2-az2 = "172.30.16.0/20" }
    nat_subnet_cidr = "172.30.255.0/24"
  }
  assert {
    condition     = output.cluster_created_by_module && output.eks_cluster_auto_mode
    error_message = "New clusters must retain the default auto mode configuration."
  }
  assert {
    condition     = length(module.eks) == 1 && length(module.vpc) == 1 && length(module.existing_eks) == 0
    error_message = "The create-cluster path must retain its EKS and VPC module addresses."
  }
  assert {
    condition     = keys(aws_eks_pod_identity_association.main) == ["sierra"] && aws_eks_pod_identity_association.main["sierra"].namespace == "sierra"
    error_message = "The default Pod Identity association address and namespace must remain unchanged."
  }
}
