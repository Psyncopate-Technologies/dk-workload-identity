terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.10"
    }
  }
}
