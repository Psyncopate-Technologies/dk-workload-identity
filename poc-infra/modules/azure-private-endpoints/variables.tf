variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "dk-confluent-poc"
}

variable "location" {
  description = "Azure region (must match the Confluent PL attachment region)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to place the private endpoints + DNS zone links in."
  type        = string
}

variable "private_link_attachment_id" {
  description = "Confluent private_link_attachment ID (platt-*)."
  type        = string
}

variable "private_link_service_alias" {
  description = "Azure Private Link Service alias emitted by the Confluent PL attachment."
  type        = string
}

variable "private_link_dns_domain" {
  description = "Confluent PL DNS domain (e.g. eastus.azure.private.confluent.cloud)."
  type        = string
}

variable "confluent_environment_id" {
  description = "Confluent environment ID (env-*) the access points live under."
  type        = string
}

variable "tiers" {
  description = <<EOT
Map of tier name (nonprod, prod) -> per-tier endpoint config:
  vnet_id                   - VNet to link the private DNS zone into.
  subnet_id                 - Subnet for the Private Endpoint NIC.
  access_point_display_name - Name of the Confluent PrivateLink Access Point.
  cluster_id                - Associated Kafka cluster (lkc-*); drives per-broker DNS records.
  broker_count              - Number of per-broker DNS records (<cluster-id>-g000..g<N-1>). Default 10.
EOT
  type = map(object({
    vnet_id                   = string
    subnet_id                 = string
    access_point_display_name = string
    cluster_id                = string
    broker_count              = optional(number, 10)
  }))
}

variable "tags" {
  description = "Tags applied to Azure resources."
  type        = map(string)
  default     = {}
}
