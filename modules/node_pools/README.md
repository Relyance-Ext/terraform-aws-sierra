# `node_pools` module

## Introduction

This submodule adds support for custom node pools.
This is required to add custom tags to your auto mode nodes.
AWS provides tools to require that all resources have certain tags,
but makes it far from straightforward to add tags to auto mode nodes.

## Implementation Overview

* This takes advantage of new policy on cluster role in the `eks` module,
  which allows creation of nodes with tags. This has been added in `modules/eks/iam.tf`.
* Custom node class is identical to the `default` node class created by EKS,
  except that it has user-specified tags on it (root's `default_tags` variable).
* Custom node pools mirror the `general-purpose` and `system` node pools, except
  that they use the custom node class instead of the default one.
* In environments with strict node policies, only the custom node class and pools
  will be able to create nodes to host pods.

<!-- Everything below this line is output from terraform-docs markdown table -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.nodepool](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.tagged_nodeclass](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [terraform_data.auto_node_role_trigger](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | name of the cluster for the node pool | `string` | n/a | yes |
| <a name="input_node_tags"></a> [node\_tags](#input\_node\_tags) | tags to apply to the nodes | `map(string)` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | name of the role for custom-tagged auto mode nodes | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | subnets in which to create the nodes | `set(string)` | n/a | yes |

## Outputs

No outputs.
