locals {
  kafka_rb_crn_prefix = "crn://confluent.cloud/organization=${var.confluent_organization_id}/environment=${var.confluent_environment_id}/cloud-cluster=${var.kafka_cluster_id}/kafka=${var.kafka_cluster_id}"

  write_topic_bindings = merge([
    for wl_key, wl in var.workloads : {
      for prefix in wl.write_topic_prefixes :
      "${wl_key}--write-topic--${prefix}" => { workload = wl_key, prefix = prefix }
    }
  ]...)

  read_topic_bindings = merge([
    for wl_key, wl in var.workloads : {
      for prefix in wl.read_topic_prefixes :
      "${wl_key}--read-topic--${prefix}" => { workload = wl_key, prefix = prefix }
    }
  ]...)

  read_group_bindings = merge([
    for wl_key, wl in var.workloads : {
      for prefix in wl.consumer_group_prefixes :
      "${wl_key}--read-group--${prefix}" => { workload = wl_key, prefix = prefix }
    }
  ]...)

  manage_topic_bindings = merge([
    for wl_key, wl in var.workloads : {
      for prefix in wl.manage_topic_prefixes :
      "${wl_key}--manage-topic--${prefix}" => { workload = wl_key, prefix = prefix }
    }
  ]...)
}

resource "confluent_identity_pool" "workload" {
  for_each = var.workloads

  identity_provider {
    id = var.identity_provider_id
  }

  display_name   = "${var.name_prefix}-${var.environment_name}-${each.key}"
  description    = coalesce(each.value.description, "Workload pool for ${each.key} (${var.environment_name})")
  identity_claim = "claims.sub"

  # v2 Entra tokens (requestedAccessTokenVersion=2) emit aud as the client ID GUID,
  # not the Application ID URI. The PowerShell side sets v2 on every app we create.
  filter = "claims.tid == \"${var.entra_tenant_id}\" && claims.aud == \"${each.value.app_client_id}\""
}

resource "confluent_role_binding" "write_topic" {
  for_each = local.write_topic_bindings

  principal   = "User:${confluent_identity_pool.workload[each.value.workload].id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${local.kafka_rb_crn_prefix}/topic=${each.value.prefix}*"
}

resource "confluent_role_binding" "read_topic" {
  for_each = local.read_topic_bindings

  principal   = "User:${confluent_identity_pool.workload[each.value.workload].id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${local.kafka_rb_crn_prefix}/topic=${each.value.prefix}*"
}

resource "confluent_role_binding" "read_group" {
  for_each = local.read_group_bindings

  principal   = "User:${confluent_identity_pool.workload[each.value.workload].id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${local.kafka_rb_crn_prefix}/group=${each.value.prefix}*"
}

resource "confluent_role_binding" "manage_topic" {
  for_each = local.manage_topic_bindings

  principal   = "User:${confluent_identity_pool.workload[each.value.workload].id}"
  role_name   = "DeveloperManage"
  crn_pattern = "${local.kafka_rb_crn_prefix}/topic=${each.value.prefix}*"
}
