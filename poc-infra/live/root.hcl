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
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}
