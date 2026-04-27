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
  app_client_ids         - List of Entra app registration (client) IDs that route into this pool.
                           Combined with OR in the pool filter so multiple Entra apps can share
                           one logical workload identity (e.g. one app per region or per service
                           that all need the same Kafka access). Must be non-empty.
  description            - Optional description shown in the Confluent Console.

Topic / group access lists — use *_prefixes for prefix-match resources (CRN topic=<prefix>*),
*_names for exact-match resources (CRN topic=<name>). Any list defaults to empty; omit fields
that don't apply.

  write_topic_prefixes    - Prefix-match topics granted DeveloperWrite.
  write_topic_names       - Exact-match topics granted DeveloperWrite.
  read_topic_prefixes     - Prefix-match topics granted DeveloperRead.
  read_topic_names        - Exact-match topics granted DeveloperRead.
  manage_topic_prefixes   - Prefix-match topics granted DeveloperManage (create/delete/alter).
  manage_topic_names      - Exact-match topics granted DeveloperManage.
  consumer_group_prefixes - Prefix-match consumer groups granted DeveloperRead.
  consumer_group_names    - Exact-match consumer groups granted DeveloperRead.
EOT
  type = map(object({
    app_client_ids          = list(string)
    description             = optional(string)
    write_topic_prefixes    = optional(list(string), [])
    write_topic_names       = optional(list(string), [])
    read_topic_prefixes     = optional(list(string), [])
    read_topic_names        = optional(list(string), [])
    manage_topic_prefixes   = optional(list(string), [])
    manage_topic_names      = optional(list(string), [])
    consumer_group_prefixes = optional(list(string), [])
    consumer_group_names    = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for wl in var.workloads : length(wl.app_client_ids) > 0])
    error_message = "Each workload must declare at least one app_client_ids entry."
  }
}
