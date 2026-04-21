variable "environment_name" {
  description = "Logical environment name (dev, uat, prod). Used only for resource display names."
  type        = string
}

variable "confluent_organization_id" {
  description = "Confluent Cloud organization ID (UUID). Used to build role-binding CRNs."
  type        = string
}

variable "confluent_environment_id" {
  description = "Confluent Cloud environment ID (e.g., env-xxxxxx)."
  type        = string
}

variable "kafka_cluster_id" {
  description = "Confluent Cloud Kafka cluster ID (e.g., lkc-xxxxxx)."
  type        = string
}

variable "entra_tenant_id" {
  description = "Microsoft Entra tenant ID (used in the identity pool filter as claims.tid)."
  type        = string
}

variable "entra_issuer" {
  description = "Entra OIDC issuer URL. Defaults to https://login.microsoftonline.com/<tenant_id>/v2.0 when null."
  type        = string
  default     = null
}

variable "entra_jwks_uri" {
  description = "Entra JWKS endpoint. Defaults to https://login.microsoftonline.com/<tenant_id>/discovery/v2.0/keys when null."
  type        = string
  default     = null
}

variable "producer_app_client_id" {
  description = "Entra app registration (client) ID for the producer workload. Used to build the aud filter api://<id>."
  type        = string
}

variable "consumer_app_client_id" {
  description = "Entra app registration (client) ID for the consumer workload. Used to build the aud filter api://<id>."
  type        = string
}

variable "topic_prefix" {
  description = "Kafka topic prefix governed by RBAC (identical across envs per project convention)."
  type        = string
  default     = "dkp"
}

variable "consumer_group_prefix" {
  description = "Kafka consumer group prefix governed by RBAC."
  type        = string
  default     = "dkp"
}
