include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/azure-private-endpoints"
}

dependency "network" {
  config_path = "../azure-network"

  mock_outputs = {
    resource_group_name         = "rg-mock"
    location                    = "eastus"
    vnet_ids                    = { nonprod = "mock-vnet-nonprod", prod = "mock-vnet-prod" }
    private_endpoint_subnet_ids = { nonprod = "mock-subnet-nonprod", prod = "mock-subnet-prod" }
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

dependency "platform" {
  config_path = "../confluent-platform"

  mock_outputs = {
    environment_id              = "env-mock00"
    private_link_attachment_id  = "platt-mock00"
    private_link_service_alias  = "mock.eastus.azure.privatelinkservice"
    private_link_dns_domain     = "eastus.azure.private.confluent.cloud"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

inputs = {
  name_prefix                = "dk-confluent-poc"
  location                   = dependency.network.outputs.location
  resource_group_name        = dependency.network.outputs.resource_group_name
  private_link_attachment_id = dependency.platform.outputs.private_link_attachment_id
  private_link_service_alias = dependency.platform.outputs.private_link_service_alias
  private_link_dns_domain    = dependency.platform.outputs.private_link_dns_domain
  confluent_environment_id   = dependency.platform.outputs.environment_id

  tiers = {
    nonprod = {
      vnet_id                   = dependency.network.outputs.vnet_ids["nonprod"]
      subnet_id                 = dependency.network.outputs.private_endpoint_subnet_ids["nonprod"]
      access_point_display_name = "DK-POC-NONPROD-ACCESSPOINT"
    }
    prod = {
      vnet_id                   = dependency.network.outputs.vnet_ids["prod"]
      subnet_id                 = dependency.network.outputs.private_endpoint_subnet_ids["prod"]
      access_point_display_name = "DK-POC-PROD-ACCESSPOINT"
    }
  }

  tags = {
    project = "dk-workload-identity"
    purpose = "poc"
    owner   = "ayele.admassu@psyncopate.com"
  }
}
