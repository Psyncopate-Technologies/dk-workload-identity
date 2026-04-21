output "resource_group_name" {
  description = "Name of the resource group holding the PoC network."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure region the resource group is in."
  value       = azurerm_resource_group.this.location
}

output "vnet_ids" {
  description = "Map of tier -> virtual network ID."
  value       = { for k, v in azurerm_virtual_network.this : k => v.id }
}

output "private_endpoint_subnet_ids" {
  description = "Map of tier -> subnet ID for Confluent Private Endpoints."
  value       = { for k, s in azurerm_subnet.private_endpoints : k => s.id }
}
