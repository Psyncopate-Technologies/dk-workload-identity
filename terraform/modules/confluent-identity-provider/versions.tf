terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.10"
    }
    # Declared for the AKV data sources in the root-generated provider.tf.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
