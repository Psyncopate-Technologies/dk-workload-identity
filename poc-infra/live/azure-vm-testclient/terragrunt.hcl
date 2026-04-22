include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/azure-vm-testclient"
}

dependency "network" {
  config_path = "../azure-network"

  mock_outputs = {
    resource_group_name = "rg-mock"
    location            = "eastus"
    compute_subnet_ids  = { nonprod = "mock-subnet-nonprod" }
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

inputs = {
  name_prefix         = "dk-confluent-poc"
  location            = dependency.network.outputs.location
  resource_group_name = dependency.network.outputs.resource_group_name
  subnet_id           = dependency.network.outputs.compute_subnet_ids["nonprod"]

  # Read from Ayele's laptop; override via TF_VAR_admin_ssh_public_key if needed.
  admin_ssh_public_key = file(pathexpand("~/.ssh/id_rsa.pub"))

  tags = {
    project = "dk-workload-identity"
    purpose = "poc-kafka-smoke-test"
    owner   = "ayele.admassu@psyncopate.com"
  }
}
