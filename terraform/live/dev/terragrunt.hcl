include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/confluent-workload-pools"
}

# Org-level identity provider is produced by the _org stack.
dependency "provider" {
  config_path = "../_org"

  mock_outputs = {
    identity_provider_id = "op-mock00"
  }
  # init is included so a fresh repo can plan dev/uat/prd before _org is applied.
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

# Workloads + topic/group access lists live in workloads.json next to this file.
# DKP edits workloads.json without touching HCL.
locals {
  config = jsondecode(file("${get_terragrunt_dir()}/workloads.json"))
}

inputs = {
  environment_name          = "dev"
  identity_provider_id      = dependency.provider.outputs.identity_provider_id
  entra_tenant_id           = local.config.entra_tenant_id
  confluent_organization_id = local.config.confluent_organization_id
  confluent_environment_id  = local.config.confluent_environment_id
  kafka_cluster_id          = local.config.kafka_cluster_id
  workloads                 = local.config.workloads
}
