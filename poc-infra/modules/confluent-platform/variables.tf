variable "name_prefix" {
  description = "Prefix for Confluent resource display names."
  type        = string
  default     = "dk-confluent-poc"
}

variable "environment_display_name" {
  description = "Display name for the Confluent Cloud environment (mirrors DKP-AZ1-STREAMING-MESH)."
  type        = string
}

variable "stream_governance_package" {
  description = "Stream Governance package. One of: ESSENTIALS, ADVANCED."
  type        = string
  default     = "ADVANCED"
}

variable "cloud" {
  description = "Cloud provider."
  type        = string
  default     = "AZURE"
}

variable "region" {
  description = "Cloud region (e.g. eastus)."
  type        = string
  default     = "eastus"
}

variable "clusters" {
  description = <<EOT
Map of Enterprise clusters to create. Key is the tier name (nonprod, prod).
Each value is a display_name suffix; the full name is {name_prefix}-{key}-{display_name_suffix}.
EOT
  type = map(object({
    display_name_suffix = string
    availability        = optional(string, "SINGLE_ZONE") # SINGLE_ZONE or HIGH
  }))
}

variable "private_link_gateway_display_name" {
  description = "Display name for the PrivateLink Attachment gateway (mirrors DKP-AZ1-PROD-PVTLINK-GATEWAY)."
  type        = string
}
