locals {
  relyance_taints = {
    relyance = {
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }
  ssd_taints = {
    ssd = {
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }

  # TODO: enable configuration (with guard rails) of the scaling and update configs here.
  # TODO: enable actual autoscaling (node group alone is insufficient).
  node_groups = {
    base = {
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
    cpu4_ram16 = {
      scaling_config = {
        desired_size = 2 # Until we figure out autoscaling, a couple nodes for redlp + gai-analyzer
        max_size     = 2
        min_size     = 0
      }
      update_config = {
        max_unavailable = 1
      }
      instance_types = ["t3a.xlarge"]
      labels = {
        nodetype = "mediummemory"
        relyance = "true"
      }
      taints = local.relyance_taints
    },
    cpu8_ram64_ssd300 = {
      scaling_config = {
        desired_size = 1 # Until we figure out autoscaling, one node for gai
        max_size     = 2
        min_size     = 0
      }
      update_config = {
        max_unavailable = 1
      }
      instance_types = ["z1d.2xlarge"]
      labels = {
        nodetype = "highmemory"
        relyance = "true"
      }
      taints = merge(local.relyance_taints, local.ssd_taints)
    }
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

    subnet_ids = [
      for az in data.aws_availability_zones.all.zone_ids : aws_subnet.main[az].id
    ]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.main.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = local.default_tags
}

# Node groups
resource "aws_launch_template" "main" {
  name = var.base_name

  metadata_options {
    http_tokens = var.eks_require_metadata_token ? "required" : "optional"
    #checkov:skip=CKV_AWS_341:Simplified IAM with single role for cluster requires hop limit 2
    http_put_response_hop_limit = 2 # Required for kubernetes pods to use node identity
  }
  key_name = var.ssh_key_pair

  user_data = filebase64("${path.module}/src/launch-script.sh")
}

resource "aws_eks_node_group" "main" {
  for_each = local.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.base_name}_${each.key}"
  node_role_arn   = aws_iam_role.main.arn
  subnet_ids      = local.subnet_ids
  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }
  update_config {
    max_unavailable = each.value.update_config.max_unavailable
  }

  instance_types = each.value.instance_types
  labels         = each.value.labels
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = local.default_tags

  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  # Don't create the node pool until the node role has all the policies it needs.
  depends_on = [aws_iam_role_policy_attachment.main]
}

# Add-ons. Declare independently (rather than for_each) to enable custom configurations

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  tags         = local.default_tags

  depends_on = [aws_eks_node_group.main["base"]] # Don't try to create until nodes exist to run it.
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  tags         = local.default_tags
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  tags         = local.default_tags
}
