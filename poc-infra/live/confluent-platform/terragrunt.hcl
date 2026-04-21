include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/confluent-platform"
}

inputs = {
  name_prefix              = "dk-confluent-poc"
  environment_display_name = "DK-POC-STREAMING-MESH"
  stream_governance_package = "ADVANCED"

  cloud  = "AZURE"
  region = "eastus"

  clusters = {
    nonprod = {
      display_name_suffix = "enterprise"
      availability        = "SINGLE_ZONE"
    }
    prod = {
      display_name_suffix = "enterprise"
      availability        = "HIGH"
    }
  }

  private_link_gateway_display_name = "DK-POC-PVTLINK-GATEWAY"
}
