variable "environment_name" {
  description = "Logical env ({env} slug in dk-confluent-{env}-{domain}-{workload}). One of: dev, uat, prd."
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prd"], var.environment_name)
    error_message = "environment_name must be one of: dev, uat, prd."
  }
}

variable "name_prefix" {
  description = "Prefix for pool display names. Project convention is 'dk-confluent'."
  type        = string
  default     = "dk-confluent"
}

variable "identity_provider_id" {
  description = "Existing Confluent OIDC identity provider ID (op-*). Created by the _org stack for PoC; DK supplies their existing one."
  type        = string
}

variable "entra_tenant_id" {
  description = "Microsoft Entra tenant ID. Used in the pool filter as claims.tid."
  type        = string
}

variable "confluent_organization_id" {
  description = "Confluent Cloud organization ID (UUID)."
  type        = string
}

variable "confluent_environment_id" {
  description = "Confluent Cloud environment ID (env-*)."
  type        = string
}

variable "kafka_cluster_id" {
  description = "Confluent Cloud Kafka cluster ID (lkc-*)."
  type        = string
}

variable "workloads" {
  description = <<EOT
Map of workloads to create pools for. Key is {domain}-{workload}, combined with name_prefix and environment_name
to produce the display name (e.g. 'mergerarb-madam' under env 'dev' becomes 'dk-confluent-dev-mergerarb-madam').

Each workload:
  app_client_id          - Entra app registration (client) ID. Used to build api://<id> aud filter.
  description            - Optional description shown in the Confluent Console.
  write_topic_prefixes   - Topic prefixes (without trailing *) granted DeveloperWrite.
  read_topic_prefixes    - Topic prefixes (without trailing *) granted DeveloperRead.
  consumer_group_prefixes - Consumer-group prefixes granted DeveloperRead.
EOT
  type = map(object({
    app_client_id           = string
    description             = optional(string)
    write_topic_prefixes    = optional(list(string), [])
    read_topic_prefixes     = optional(list(string), [])
    consumer_group_prefixes = optional(list(string), [])
  }))
  default = {}
}
