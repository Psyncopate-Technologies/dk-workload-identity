output "identity_provider_id" {
  description = "Confluent OIDC identity provider ID backing the Entra tenant."
  value       = confluent_identity_provider.entra.id
}

output "producer_identity_pool_id" {
  description = "Identity pool ID for the producer workload. Use as principal/pool ID in client SASL config."
  value       = confluent_identity_pool.producer.id
}

output "consumer_identity_pool_id" {
  description = "Identity pool ID for the consumer workload. Use as principal/pool ID in client SASL config."
  value       = confluent_identity_pool.consumer.id
}

output "producer_pool_filter" {
  description = "Filter expression applied to the producer pool (for verification)."
  value       = confluent_identity_pool.producer.filter
}

output "consumer_pool_filter" {
  description = "Filter expression applied to the consumer pool (for verification)."
  value       = confluent_identity_pool.consumer.filter
}
