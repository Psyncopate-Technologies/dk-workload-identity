output "identity_provider_id" {
  description = "Confluent OIDC identity provider ID (op-*). Pass this into the confluent-workload-pools module."
  value       = confluent_identity_provider.this.id
}

output "display_name" {
  description = "Confluent identity provider display name."
  value       = confluent_identity_provider.this.display_name
}

output "issuer" {
  description = "Resolved Entra issuer URL."
  value       = confluent_identity_provider.this.issuer
}
