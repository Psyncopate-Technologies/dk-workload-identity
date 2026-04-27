generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# Azure provider — used only to read DKP's Confluent admin API key + secret
# from Azure Key Vault. Auth to Azure comes from ARM_* env vars set by the
# GitHub Actions workflow (ARM_USE_OIDC=true) or the local az-cli session.
provider "azurerm" {
  features {}
}

data "azurerm_key_vault" "corp_it" {
  name                = var.azure_key_vault_name
  resource_group_name = var.azure_key_vault_resource_group_name
}

data "azurerm_key_vault_secret" "confluent_admin_key" {
  name         = "confluent-admin-key"
  key_vault_id = data.azurerm_key_vault.corp_it.id
}

data "azurerm_key_vault_secret" "confluent_admin_secret" {
  name         = "confluent-admin-secret"
  key_vault_id = data.azurerm_key_vault.corp_it.id
}

provider "confluent" {
  cloud_api_key    = data.azurerm_key_vault_secret.confluent_admin_key.value
  cloud_api_secret = data.azurerm_key_vault_secret.confluent_admin_secret.value
}

variable "azure_key_vault_name" {
  description = "Name of the Azure Key Vault that stores the Confluent admin API key + secret. Supply via TF_VAR_azure_key_vault_name."
  type        = string
}

variable "azure_key_vault_resource_group_name" {
  description = "Resource group of the Azure Key Vault above. Supply via TF_VAR_azure_key_vault_resource_group_name."
  type        = string
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
    resource_group_name  = get_env("TG_STATE_RESOURCE_GROUP", "rg-dk-confluent-poc-tfstate")
    storage_account_name = get_env("TG_STATE_STORAGE_ACCOUNT", "dkconfluentpoctfstate")
    container_name       = get_env("TG_STATE_CONTAINER", "tfstate")
    # Flat naming to match DKP's existing convention in the confluent container, e.g.
    # confluent-DEVworkload-identity.tfstate (note: no separator between env and component).
    # Stack dirs map: _org → ORG, dev → DEV, uat → UAT, prd → PRD.
    key = "confluent-${upper(replace(path_relative_to_include(), "_", ""))}workload-identity.tfstate"
    tenant_id            = get_env("ARM_TENANT_ID", "7bab0bc1-bb61-48d7-b2d4-79825c2ac6b8")
    subscription_id      = get_env("ARM_SUBSCRIPTION_ID", "e2fc4b68-6dd0-4c89-99c6-d6b16f9a0eba")
    use_azuread_auth     = true
  }
}
