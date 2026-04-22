include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/confluent-workload-pools"
}

dependency "provider" {
  config_path = "../_org"

  mock_outputs = {
    identity_provider_id = "op-mock00"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

locals {
  config = jsondecode(file("${get_terragrunt_dir()}/workloads.json"))
}

inputs = {
  environment_name          = "uat"
  identity_provider_id      = dependency.provider.outputs.identity_provider_id
  entra_tenant_id           = local.config.entra_tenant_id
  confluent_organization_id = local.config.confluent_organization_id
  confluent_environment_id  = local.config.confluent_environment_id
  kafka_cluster_id          = local.config.kafka_cluster_id
  workloads                 = local.config.workloads
}
