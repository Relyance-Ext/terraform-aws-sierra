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
  mock_data "aws_eks_cluster" {
    defaults = {
      name                  = "Customer-Cluster"
      endpoint              = "https://example.invalid"
      identity              = [{ oidc = [{ issuer = "https://oidc.example.invalid" }] }]
      certificate_authority = [{ data = "Zm9v" }]
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111122223333:role/Relyance_Sierra" }
  }
}
mock_provider "http" {}
mock_provider "random" {}
mock_provider "kubernetes" {}

variables {
  create_vpc_and_eks                     = false
  existing_eks_cluster_name              = "Customer-Cluster"
  require_existing_eks_cluster_auto_mode = false
  require_existing_eks_cluster_addons    = false
  assumable_account_ids                  = ["444455556666"]
}

run "defaults_create_nothing_new" {
  command = plan
  assert {
    condition     = length(aws_iam_role_policy.byok_secrets) == 0
    error_message = "byok policy must not exist by default"
  }
  assert {
    condition     = keys(aws_eks_pod_identity_association.main) == ["sierra"]
    error_message = "only the sierra association by default"
  }
  assert {
    condition     = aws_eks_pod_identity_association.main["sierra"].namespace == "sierra" && aws_eks_pod_identity_association.main["sierra"].service_account == "relyance"
    error_message = "sierra association unchanged"
  }
}

run "read_write_with_kms" {
  command = plan
  variables {
    byok_secret_arn_patterns = [
      "arn:aws:secretsmanager:us-west-2:111122223333:secret:relyance/inhost/*",
      "arn:aws:secretsmanager:us-east-1:111122223333:secret:relyance/inhost/*",
    ]
    byok_secret_kms_key_arns              = ["arn:aws:kms:us-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"]
    additional_service_account_namespaces = ["inhost"]
  }
  assert {
    condition = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[0].Action == [
    "secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue"]
    error_message = "sm actions wrong"
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Action == ["kms:Decrypt", "kms:GenerateDataKey"]
    error_message = "kms actions wrong"
  }
  assert {
    condition = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Condition.StringEquals["kms:ViaService"] == [
    "secretsmanager.us-west-2.amazonaws.com", "secretsmanager.us-east-1.amazonaws.com"]
    error_message = "viaservice wrong"
  }
  assert {
    condition     = aws_eks_pod_identity_association.main["inhost"].namespace == "inhost" && aws_eks_pod_identity_association.main["inhost"].service_account == "relyance"
    error_message = "inhost association missing"
  }
  assert {
    condition     = aws_eks_pod_identity_association.main["sierra"].namespace == "sierra"
    error_message = "sierra association must remain"
  }
}

run "read_only_no_kms" {
  command = plan
  variables {
    byok_secret_arn_patterns = ["arn:aws:secretsmanager:*:111122223333:secret:relyance/inhost/*"]
    byok_secret_write_back   = false
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[0].Action == ["secretsmanager:GetSecretValue"]
    error_message = "read-only actions wrong"
  }
  assert {
    condition     = length(jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement) == 1
    error_message = "no kms statement expected"
  }
}

run "read_only_kms" {
  command = plan
  variables {
    byok_secret_arn_patterns = ["arn:aws:secretsmanager:*:111122223333:secret:relyance/inhost/*"]
    byok_secret_kms_key_arns = ["arn:aws:kms:us-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"]
    byok_secret_write_back   = false
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Action == ["kms:Decrypt"]
    error_message = "kms read-only wrong"
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Condition.StringLike["kms:ViaService"] == ["secretsmanager.*.amazonaws.com"]
    error_message = "a wildcard-region pattern must allow Secrets Manager in any region"
  }
  assert {
    condition     = !contains(keys(jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Condition), "StringEquals")
    error_message = "a wildcard-region pattern must not keep a StringEquals region list"
  }
  assert {
    condition     = output.byok_secret_write_back == false
    error_message = "output must follow byok_secret_write_back"
  }
}

run "partial_wildcard_region_with_literal_region" {
  command = plan
  variables {
    byok_secret_arn_patterns = [
      "arn:aws:secretsmanager:us-east-1:111122223333:secret:relyance/inhost/*",
      "arn:aws:secretsmanager:eu-*:111122223333:secret:relyance/inhost/*",
    ]
    byok_secret_kms_key_arns = ["arn:aws:kms:us-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"]
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Condition == { StringLike = { "kms:ViaService" = ["secretsmanager.*.amazonaws.com"] } }
    error_message = "any wildcard-region pattern must switch the condition to StringLike"
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Action == ["kms:Decrypt", "kms:GenerateDataKey"]
    error_message = "kms actions wrong"
  }
  assert {
    condition     = output.byok_secret_write_back == true
    error_message = "output must default to true"
  }
}

run "china_partition_uses_cn_dns_suffix" {
  command = plan
  override_data {
    target = data.aws_partition.current
    values = { partition = "aws-cn", dns_suffix = "amazonaws.com.cn" }
  }
  override_data {
    target = data.aws_region.current
    values = { name = "cn-north-1" }
  }
  variables {
    byok_secret_arn_patterns = ["arn:aws-cn:secretsmanager:cn-north-1:111122223333:secret:relyance/inhost/*"]
    byok_secret_kms_key_arns = ["arn:aws-cn:kms:cn-north-1:111122223333:key/00000000-0000-0000-0000-000000000000"]
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Condition == { StringEquals = { "kms:ViaService" = ["secretsmanager.cn-north-1.amazonaws.com.cn"] } }
    error_message = "aws-cn must use the amazonaws.com.cn DNS suffix in kms:ViaService"
  }
}

run "china_partition_wildcard_region" {
  command = plan
  override_data {
    target = data.aws_partition.current
    values = { partition = "aws-cn", dns_suffix = "amazonaws.com.cn" }
  }
  variables {
    byok_secret_arn_patterns = ["arn:aws-cn:secretsmanager:*:111122223333:secret:relyance/inhost/*"]
    byok_secret_kms_key_arns = ["arn:aws-cn:kms:cn-north-1:111122223333:key/00000000-0000-0000-0000-000000000000"]
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.byok_secrets[0].policy).Statement[1].Condition == { StringLike = { "kms:ViaService" = ["secretsmanager.*.amazonaws.com.cn"] } }
    error_message = "aws-cn wildcard region must use secretsmanager.*.amazonaws.com.cn"
  }
}

run "bad_pattern_rejected" {
  command = plan
  variables {
    byok_secret_arn_patterns = ["arn:aws:s3:::bucket/*"]
  }
  expect_failures = [var.byok_secret_arn_patterns]
}

run "bad_kms_rejected" {
  command = plan
  variables {
    byok_secret_arn_patterns = ["arn:aws:secretsmanager:us-west-2:111122223333:secret:relyance/inhost/*"]
    byok_secret_kms_key_arns = ["alias/foo"]
  }
  expect_failures = [var.byok_secret_kms_key_arns]
}

run "kms_without_patterns_rejected" {
  command = plan
  variables {
    byok_secret_kms_key_arns = ["arn:aws:kms:us-west-2:111122223333:key/00000000-0000-0000-0000-000000000000"]
  }
  expect_failures = [var.byok_secret_kms_key_arns]
}

run "sierra_ns_rejected" {
  command = plan
  variables {
    additional_service_account_namespaces = ["sierra"]
  }
  expect_failures = [var.additional_service_account_namespaces]
}

run "bad_ns_rejected" {
  command = plan
  variables {
    additional_service_account_namespaces = ["In_Host"]
  }
  expect_failures = [var.additional_service_account_namespaces]
}
