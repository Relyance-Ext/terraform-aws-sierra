locals {

  assumable_roles = (
    var.assume_all_roles
    ? ["*"]
    : [for account_id in var.assumable_account_ids : "arn:aws:iam::${account_id}:role/*"]
  )

  standard_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]
  customer_policies = var.policy != null ? [var.policy] : []

  node_policies = toset(concat(
    local.standard_policies,
    local.customer_policies
  ))

  eks_policies = toset([
    "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy",
  ])

  node_roles = {
    self = "${var.base_name}_Node" # Self-managed nodes
    auto = "${var.base_name}_Auto" # EKS auto mode nodes
  }

  node_policy_bindings_list = flatten(
    [
      for role_id, role in local.node_roles : [
        for policy in local.node_policies : {
          role_id = role_id
          role    = role
          policy  = policy
        }
      ]
    ]
  )

  node_policy_bindings = {
    for info in local.node_policy_bindings_list : "${info.role_id}_${info.policy}" => info
  }
}

# Will be used by Relyance code running in pods
resource "aws_iam_role" "main" {
  name = var.base_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Sid    = "EksPodIdentity"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      },
    ]
  })

  tags = local.default_tags
}

# Inline policy for resource assumption.
resource "aws_iam_role_policy" "main" {
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "sts:AssumeRole",
        Effect   = "Allow",
        Resource = local.assumable_roles
      }
    ]
  })
}


# Used by self-managed and auto-mode EKS nodes
resource "aws_iam_role" "node" {
  for_each = local.node_roles

  name = each.value
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = local.node_policy_bindings

  role       = each.value.role
  policy_arn = each.value.policy

  depends_on = [aws_iam_role.node]
}


######

resource "aws_iam_role" "eks" {
  name = "${var.base_name}_Cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "eks" {
  for_each = local.eks_policies

  role       = aws_iam_role.eks.name
  policy_arn = each.value
}

######

resource "aws_iam_role" "reader" {
  name = "${var.base_name}_Reader"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AssumeRole"
        Principal = {
          AWS = local.s3_read_access_principals
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" : random_uuid.reader_external_id.result
          }
        }
      },
    ]
  })
}

resource "random_uuid" "reader_external_id" {}
