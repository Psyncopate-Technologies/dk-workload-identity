generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud Cloud API Key. Supply via TF_VAR_confluent_cloud_api_key."
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud Cloud API Secret. Supply via TF_VAR_confluent_cloud_api_secret."
  type        = string
  sensitive   = true
}
EOF
}

remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # Override any of these via env vars before running terragrunt.
    # Defaults target Ayele's PoC; DK overrides these for their own tenant/account.
    resource_group_name  = get_env("TG_STATE_RESOURCE_GROUP", "rg-dk-confluent-poc-tfstate")
    storage_account_name = get_env("TG_STATE_STORAGE_ACCOUNT", "dkconfluentpoctfstate")
    container_name       = get_env("TG_STATE_CONTAINER", "tfstate")
    key                  = "terraform/${path_relative_to_include()}/terraform.tfstate"
    tenant_id            = get_env("ARM_TENANT_ID", "1b9dca15-4db4-4905-8725-d318d11c6875")
    subscription_id      = get_env("ARM_SUBSCRIPTION_ID", "e2fc4b68-6dd0-4c89-99c6-d6b16f9a0eba")
    use_azuread_auth     = true
  }
}
