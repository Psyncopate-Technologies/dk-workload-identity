locals {
  producer_aud = "api://${var.producer_app_client_id}"
  consumer_aud = "api://${var.consumer_app_client_id}"

  kafka_rb_crn_prefix = "crn://confluent.cloud/organization=${var.confluent_organization_id}/environment=${var.confluent_environment_id}/cloud-cluster=${var.kafka_cluster_id}/kafka=${var.kafka_cluster_id}"
}

resource "confluent_identity_provider" "entra" {
  display_name = "entra-${var.environment_name}"
  description  = "Microsoft Entra ID OIDC provider (${var.environment_name})"
  issuer       = var.entra_issuer
  jwks_uri     = var.entra_jwks_uri
}

resource "confluent_identity_pool" "producer" {
  identity_provider {
    id = confluent_identity_provider.entra.id
  }

  display_name   = "producer-${var.environment_name}"
  description    = "Producer workload pool (${var.environment_name})"
  identity_claim = "claims.sub"
  filter         = "claims.tid == \"${var.entra_tenant_id}\" && claims.aud == \"${local.producer_aud}\""
}

resource "confluent_identity_pool" "consumer" {
  identity_provider {
    id = confluent_identity_provider.entra.id
  }

  display_name   = "consumer-${var.environment_name}"
  description    = "Consumer workload pool (${var.environment_name})"
  identity_claim = "claims.sub"
  filter         = "claims.tid == \"${var.entra_tenant_id}\" && claims.aud == \"${local.consumer_aud}\""
}

resource "confluent_role_binding" "producer_write" {
  principal   = "User:${confluent_identity_pool.producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${local.kafka_rb_crn_prefix}/topic=${var.topic_prefix}*"
}

resource "confluent_role_binding" "consumer_read_topic" {
  principal   = "User:${confluent_identity_pool.consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${local.kafka_rb_crn_prefix}/topic=${var.topic_prefix}*"
}

resource "confluent_role_binding" "consumer_read_group" {
  principal   = "User:${confluent_identity_pool.consumer.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${local.kafka_rb_crn_prefix}/group=${var.consumer_group_prefix}*"
}
