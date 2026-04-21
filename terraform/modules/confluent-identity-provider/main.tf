locals {
  entra_issuer   = coalesce(var.entra_issuer, "https://login.microsoftonline.com/${var.entra_tenant_id}/v2.0")
  entra_jwks_uri = coalesce(var.entra_jwks_uri, "https://login.microsoftonline.com/${var.entra_tenant_id}/discovery/v2.0/keys")
}

resource "confluent_identity_provider" "this" {
  display_name = var.display_name
  description  = var.description
  issuer       = local.entra_issuer
  jwks_uri     = local.entra_jwks_uri
}
