include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/confluent-workload-pools"
}

# Org-level identity provider is produced by the _org stack.
dependency "provider" {
  config_path = "../_org"

  # Allow `terragrunt plan` to render before _org has been applied.
  mock_outputs = {
    identity_provider_id = "op-mock00"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

inputs = {
  environment_name          = "dev"
  identity_provider_id      = dependency.provider.outputs.identity_provider_id
  entra_tenant_id           = "1b9dca15-4db4-4905-8725-d318d11c6875"
  confluent_organization_id = "0369af3f-d68c-44de-97cb-52a50017dc59"
  confluent_environment_id  = "env-1y1176"
  kafka_cluster_id          = "lkc-x9qrwg"

  # One pool per workload. Key is {domain}-{workload} — produces pool name
  # dk-confluent-dev-<key> (e.g. dk-confluent-dev-mergerarb-madam).
  workloads = {
    "mergerarb-madam" = {
      app_client_id           = "9dfb2b95-628d-4662-a8cd-88965d278cd9"
      description             = "Merger-Arb MADAM workload — dev."
      write_topic_prefixes    = ["mergerarb.madam."]
      read_topic_prefixes     = ["mergerarb.madam."]
      consumer_group_prefixes = ["mergerarb-madam-"]
    }
  }
}
