locals {
  ami_type = {
    "x86_64" = "AL2023_x86_64_STANDARD"
    "arm64"  = "AL2023_ARM_64_STANDARD"
  }

  self_managed_labels = {
    self-managed = "true"
  }

  # TODO: enable configuration (with guard rails) of the scaling and update configs here.
  node_groups = {
    base = {
      arch = "x86_64"
      scaling_config = {
        desired_size = 1
        max_size     = 2
        min_size     = 1
      }
      update_config = {
        max_unavailable = 1
      }
      instance_types = ["t3.medium"]
      labels = {
        nodetype = "lowmemory"
      }
      taints = {} # This is the default for system services to run on, so no taints.
      # Map from key to map with value and effect
    },
  }
}

resource "aws_eks_cluster" "main" {
  name     = var.base_name
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = true
    #checkov:skip=CKV_AWS_39:Public access only enabled if access CIDRs are provided
    endpoint_public_access = (length(var.eks_public_access_cidrs) > 0)
    #checkov:skip=CKV_AWS_38:Public access only enabled if access CIDRs are provided
    public_access_cidrs = var.eks_public_access_cidrs

    subnet_ids = var.subnet_ids
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = var.default_tags

  # EKS Auto Mode
  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = true
    node_pools    = ["system", "general-purpose"] # These don't get configured tags and may not comply with tag policies
    node_role_arn = aws_iam_role.node["auto"].arn
  }
  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
    service_ipv4_cidr = var.service_cidr
  }
  storage_config {
    block_storage {
      enabled = true
    }
  }
}

# Node groups
resource "aws_launch_template" "main" {
  name = var.base_name

  metadata_options {
    http_tokens = var.eks_require_metadata_token ? "required" : "optional"
    #checkov:skip=CKV_AWS_341:Simplified IAM with single role for cluster requires hop limit 2
    http_put_response_hop_limit = 2 # Required for kubernetes pods to use node identity
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = filebase64("${path.module}/src/launch-script.sh")

  tags = var.default_tags

  dynamic "tag_specifications" {
    for_each = length(var.node_tags) > 0 ? [0] : []
    content {
      resource_type = "instance"
      tags          = var.node_tags
    }
  }
}

resource "aws_eks_node_group" "main" {
  for_each = local.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.base_name}_${each.key}"
  node_role_arn   = aws_iam_role.node["self"].arn
  subnet_ids      = var.subnet_ids
  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }
  update_config {
    max_unavailable = each.value.update_config.max_unavailable
  }

  ami_type       = local.ami_type[each.value.arch]
  instance_types = each.value.instance_types
  labels         = merge(each.value.labels, local.self_managed_labels)
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = var.default_tags

  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  # Don't create the node pool until the node role has all the policies it needs.
  depends_on = [aws_iam_role_policy_attachment.node]
}

# Add-ons. Declare independently (rather than for_each) to enable custom configurations

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  tags         = var.default_tags

  depends_on = [aws_eks_node_group.main["base"]] # Don't try to create until nodes exist to run it.
}

resource "aws_eks_addon" "metrics-server" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "metrics-server"
  tags         = var.default_tags

  depends_on = [aws_eks_node_group.main["base"]] # Don't try to create until nodes exist to run it.
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  tags         = var.default_tags
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  tags         = var.default_tags
}

resource "aws_eks_addon" "pod-identity-agent" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"
  tags         = var.default_tags
}
