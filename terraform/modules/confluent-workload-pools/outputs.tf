output "identity_pool_ids" {
  description = "Map of workload_key -> identity pool ID (pool-*). Paste into client SASL config (extension_identityPoolId)."
  value       = { for k, p in confluent_identity_pool.workload : k => p.id }
}

output "identity_pool_names" {
  description = "Map of workload_key -> display name. For cross-checking in the Confluent Console."
  value       = { for k, p in confluent_identity_pool.workload : k => p.display_name }
}

output "identity_pool_filters" {
  description = "Map of workload_key -> filter expression. Cross-check claims.tid/claims.aud against a decoded JWT at jwt.ms."
  value       = { for k, p in confluent_identity_pool.workload : k => p.filter }
}
