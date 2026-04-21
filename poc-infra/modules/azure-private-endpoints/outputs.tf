output "private_endpoint_ids" {
  description = "Map of tier -> Azure Private Endpoint resource ID."
  value       = { for k, pe in azurerm_private_endpoint.this : k => pe.id }
}

output "private_endpoint_ips" {
  description = "Map of tier -> Private Endpoint NIC IP. Use as the A-record target if automatic DNS isn't wired up."
  value       = { for k, pe in azurerm_private_endpoint.this : k => try(pe.private_service_connection[0].private_ip_address, null) }
}

output "private_dns_zone_id" {
  description = "Azure Private DNS zone ID (covers both tiers)."
  value       = azurerm_private_dns_zone.this.id
}

output "confluent_access_point_ids" {
  description = "Map of tier -> Confluent access-point ID (plattc-*)."
  value       = { for k, c in confluent_private_link_attachment_connection.this : k => c.id }
}
