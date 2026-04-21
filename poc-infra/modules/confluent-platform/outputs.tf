output "environment_id" {
  description = "Confluent Cloud environment ID (env-*)."
  value       = confluent_environment.this.id
}

output "environment_display_name" {
  description = "Environment display name."
  value       = confluent_environment.this.display_name
}

output "cluster_ids" {
  description = "Map of tier -> Kafka cluster ID (lkc-*)."
  value       = { for k, c in confluent_kafka_cluster.this : k => c.id }
}

output "cluster_display_names" {
  description = "Map of tier -> Kafka cluster display name."
  value       = { for k, c in confluent_kafka_cluster.this : k => c.display_name }
}

output "cluster_bootstrap_endpoints" {
  description = "Map of tier -> bootstrap endpoint (host:port). Needed for Azure Private DNS A records."
  value       = { for k, c in confluent_kafka_cluster.this : k => c.bootstrap_endpoint }
}

output "private_link_attachment_id" {
  description = "PrivateLink Attachment ID (platt-*)."
  value       = confluent_private_link_attachment.this.id
}

output "private_link_service_alias" {
  description = "Azure Private Link Service alias the PE will target."
  value       = try(confluent_private_link_attachment.this.azure[0].private_link_service_alias, null)
}

output "private_link_dns_domain" {
  description = "DNS domain Confluent publishes bootstrap records under (e.g. eastus.azure.private.confluent.cloud)."
  value       = confluent_private_link_attachment.this.dns_domain
}
