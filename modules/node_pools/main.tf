# Node pools (required for custom tagging)
# In a perfect world, we'd put this in the EKS submodule.
# But we can't because provider can't be inside an optional module,
# and using that external provider inside the module is a circular dependency.

# Mechanism to force replacement of nodeclass if the node role name changes.
resource "terraform_data" "auto_node_role_trigger" {
  triggers_replace = {
    role_name = var.role_name
  }
}

# Settings for node pools to mirror the general-purpose and system pools.
# Fields which don't differ are specified in resource with for_each to reduce boilerplate.
locals {
  nodepools = {
    "relyance-inhost-general-purpose" : {
      consolidateAfter    = "30s"
      consolidationPolicy = "WhenEmptyOrUnderutilized"
      arch                = ["amd64"]
      taints              = []
    }
    "relyance-inhost-system" : {
      consolidateAfter    = "30s"
      consolidationPolicy = "WhenEmptyOrUnderutilized"
      arch                = ["amd64", "arm64"]
      taints = [
        {
          effect = "NoSchedule"
          key    = "CriticalAddonsOnly"
        }
      ]
    }
  }
}

# Node class identical to the default node class, but with user-specified tags
# applied to the nodes, allowing compliance with AWS tag policies.
resource "kubernetes_manifest" "tagged_nodeclass" {
  manifest = {
    "apiVersion" = "eks.amazonaws.com/v1"
    "kind"       = "NodeClass"
    "metadata" = {
      "name" = "relyance-inhost"
    }
    "spec" = {
      "role" = var.role_name
      "subnetSelectorTerms" = [
        for subnet_id in var.subnet_ids : { id = subnet_id }
      ]
      "securityGroupSelectorTerms" = [
        {
          "tags" = {
            "aws:eks:cluster-name" = var.cluster_name
          }
        }
      ]
      "tags" = var.node_tags
    }
  }

  lifecycle {
    replace_triggered_by = [
      terraform_data.auto_node_role_trigger
    ]
  }
}

# Node pools identical to the default ones created by EKS,
# but using the custom node class so the nodes will have tags,
# and can be made compliant with AWS organization node policies.
resource "kubernetes_manifest" "nodepool" {
  for_each = local.nodepools

  manifest = {
    "apiVersion" = "karpenter.sh/v1"
    "kind"       = "NodePool"
    "metadata" = {
      "name" = each.key
    }
    "spec" = {
      "disruption" = {
        "budgets" = [
          {
            "nodes" = "10%"
          },
        ]
        "consolidateAfter"    = each.value.consolidateAfter
        "consolidationPolicy" = each.value.consolidationPolicy
      }
      "template" = {
        "metadata" = {}
        "spec" = {
          "expireAfter" = "336h"
          "nodeClassRef" = {
            "group" = "eks.amazonaws.com"
            "kind"  = "NodeClass"
            "name"  = kubernetes_manifest.tagged_nodeclass.manifest.metadata.name
          }
          "requirements" = [
            {
              "key"      = "karpenter.sh/capacity-type"
              "operator" = "In"
              "values" = [
                "on-demand",
              ]
            },
            {
              "key"      = "eks.amazonaws.com/instance-category"
              "operator" = "In"
              "values" = [
                "c",
                "m",
                "r",
              ]
            },
            {
              "key"      = "eks.amazonaws.com/instance-generation"
              "operator" = "Gt"
              "values" = [
                "4",
              ]
            },
            {
              "key"      = "kubernetes.io/arch"
              "operator" = "In"
              "values"   = each.value.arch
            },
            {
              "key"      = "kubernetes.io/os"
              "operator" = "In"
              "values" = [
                "linux",
              ]
            },
          ]
          "taints"                 = each.value.taints
          "terminationGracePeriod" = "24h0m0s"
        }
      }
    }
  }
}
