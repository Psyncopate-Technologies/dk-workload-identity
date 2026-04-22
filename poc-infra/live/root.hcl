# Root Terragrunt config for the PoC infra tree.
#
# Scope: provisions the Azure + Confluent Cloud infrastructure for Ayele's PoC
# (mirrors DKP's production layout). Kept OUT of the DK deliverable — this tree
# must never ship to DK.
#
# Local state for now — moving to Azure Storage before CI apply at scale.

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.10"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
  features {}
}

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API key. Supply via TF_VAR_confluent_cloud_api_key."
  type        = string
  sensitive   = true
  default     = null
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API secret. Supply via TF_VAR_confluent_cloud_api_secret."
  type        = string
  sensitive   = true
  default     = null
}

variable "azure_subscription_id" {
  description = "Azure subscription ID. Supply via TF_VAR_azure_subscription_id."
  type        = string
  default     = null
}

variable "azure_tenant_id" {
  description = "Azure tenant ID. Supply via TF_VAR_azure_tenant_id."
  type        = string
  default     = null
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
    key                  = "poc-infra/${path_relative_to_include()}/terraform.tfstate"
    tenant_id            = get_env("ARM_TENANT_ID", "1b9dca15-4db4-4905-8725-d318d11c6875")
    subscription_id      = get_env("ARM_SUBSCRIPTION_ID", "e2fc4b68-6dd0-4c89-99c6-d6b16f9a0eba")
    use_azuread_auth     = true
  }
}
