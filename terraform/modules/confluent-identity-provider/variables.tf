variable "display_name" {
  description = "Display name shown in the Confluent Console (e.g. 'DKP Entra ID', 'DK Entra ID - PoC')."
  type        = string
}

variable "description" {
  description = "Description shown in the Confluent Console."
  type        = string
  default     = "Microsoft Entra ID OIDC identity provider."
}

variable "entra_tenant_id" {
  description = "Microsoft Entra tenant ID. Used to derive issuer and JWKS URLs when not explicitly provided."
  type        = string
}

variable "entra_issuer" {
  description = "OIDC issuer. Defaults to https://login.microsoftonline.com/<tenant_id>/v2.0."
  type        = string
  default     = null
}

variable "entra_jwks_uri" {
  description = "JWKS endpoint. Defaults to https://login.microsoftonline.com/<tenant_id>/discovery/v2.0/keys."
  type        = string
  default     = null
}
