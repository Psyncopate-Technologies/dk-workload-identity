variable "name_prefix" {
  description = "Resource name prefix. Convention: dk-confluent-poc."
  type        = string
  default     = "dk-confluent-poc"
}

variable "location" {
  description = "Azure region. Match DKP's (eastus) so the PrivateLink DNS zone aligns."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group holding the PoC network."
  type        = string
}

variable "vnets" {
  description = <<EOT
Map of VNets to create. Key is the tier name (nonprod, prod). Each:
  address_space        - CIDR block (e.g. ["10.10.0.0/16"]).
  private_endpoint_cidr - Subnet CIDR inside the VNet for Confluent Private Endpoints.
EOT
  type = map(object({
    address_space         = list(string)
    private_endpoint_cidr = string
  }))
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
