include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/azure-network"
}

inputs = {
  name_prefix         = "dk-confluent-poc"
  location            = "eastus"
  resource_group_name = "rg-dk-confluent-poc-eastus"

  # Two VNets — one per tier — mirroring DKP's nonprod/prod split.
  # Picked non-overlapping /16s that don't collide with the common 10.0.0.0/16.
  vnets = {
    nonprod = {
      address_space         = ["10.40.0.0/16"]
      private_endpoint_cidr = "10.40.1.0/24"
    }
    prod = {
      address_space         = ["10.41.0.0/16"]
      private_endpoint_cidr = "10.41.1.0/24"
    }
  }

  tags = {
    project = "dk-workload-identity"
    purpose = "poc"
    owner   = "ayele.admassu@psyncopate.com"
  }
}
