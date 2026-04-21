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

inputs = {
  environment_name          = "prd"
  identity_provider_id      = dependency.provider.outputs.identity_provider_id
  entra_tenant_id           = "REPLACE_WITH_PRD_TENANT_ID"
  confluent_organization_id = "REPLACE_WITH_PRD_ORG_ID_IF_DIFFERENT"
  confluent_environment_id  = "REPLACE_WITH_PRD_CONFLUENT_ENV_ID"
  kafka_cluster_id          = "REPLACE_WITH_PRD_KAFKA_CLUSTER_ID"

  workloads = {
    "mergerarb-madam" = {
      app_client_id           = "REPLACE_WITH_PRD_MERGERARB_MADAM_APP_CLIENT_ID"
      description             = "Merger-Arb MADAM workload — prd."
      write_topic_prefixes    = ["mergerarb.madam."]
      read_topic_prefixes     = ["mergerarb.madam."]
      consumer_group_prefixes = ["mergerarb-madam-"]
    }
  }
}
