locals {
  kafka_rb_crn_prefix = "crn://confluent.cloud/organization=${var.confluent_organization_id}/environment=${var.confluent_environment_id}/cloud-cluster=${var.kafka_cluster_id}/kafka=${var.kafka_cluster_id}"

  # Flatten workloads × each access-list field into for_each-friendly maps.
  # Key: "<workload>--<field>--<value>"  →  { workload, role, crn_suffix }
  write_topic_prefix_bindings = merge([
    for wl_key, wl in var.workloads : {
      for v in wl.write_topic_prefixes :
      "${wl_key}--write-topic-prefix--${v}" => { workload = wl_key, role = "DeveloperWrite", crn_suffix = "topic=${v}*" }
    }
  ]...)

  write_topic_name_bindings = merge([
    for wl_key, wl in var.workloads : {
      for v in wl.write_topic_names :
      "${wl_key}--write-topic-name--${v}" => { workload = wl_key, role = "DeveloperWrite", crn_suffix = "topic=${v}" }
    }
  ]...)

  read_topic_prefix_bindings = merge([
    for wl_key, wl in var.workloads : {
      for v in wl.read_topic_prefixes :
      "${wl_key}--read-topic-prefix--${v}" => { workload = wl_key, role = "DeveloperRead", crn_suffix = "topic=${v}*" }
    }
  ]...)

  read_topic_name_bindings = merge([
    for wl_key, wl in var.workloads : {
      for v in wl.read_topic_names :
      "${wl_key}--read-topic-name--${v}" => { workload = wl_key, role = "DeveloperRead", crn_suffix = "topic=${v}" }
    }
  ]...)

  manage_topic_prefix_bindings = merge([
    for wl_key, wl in var.workloads : {
      for v in wl.manage_topic_prefixes :
      "${wl_key}--manage-topic-prefix--${v}" => { workload = wl_key, role = "DeveloperManage", crn_suffix = "topic=${v}*" }
    }
  ]...)

  manage_topic_name_bindings = merge([
    for wl_key, wl in var.workloads : {
      for v in wl.manage_topic_names :
      "${wl_key}--manage-topic-name--${v}" => { workload = wl_key, role = "DeveloperManage", crn_suffix = "topic=${v}" }
    }
  ]...)

  consumer_group_prefix_bindings = merge([
    for wl_key, wl in var.workloads : {
      for v in wl.consumer_group_prefixes :
      "${wl_key}--group-prefix--${v}" => { workload = wl_key, role = "DeveloperRead", crn_suffix = "group=${v}*" }
    }
  ]...)

  consumer_group_name_bindings = merge([
    for wl_key, wl in var.workloads : {
      for v in wl.consumer_group_names :
      "${wl_key}--group-name--${v}" => { workload = wl_key, role = "DeveloperRead", crn_suffix = "group=${v}" }
    }
  ]...)

  all_bindings = merge(
    local.write_topic_prefix_bindings,
    local.write_topic_name_bindings,
    local.read_topic_prefix_bindings,
    local.read_topic_name_bindings,
    local.manage_topic_prefix_bindings,
    local.manage_topic_name_bindings,
    local.consumer_group_prefix_bindings,
    local.consumer_group_name_bindings,
  )
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
  # not the Application ID URI. The runbook / PowerShell sets v2 on every app we create.
  # CEL `in` lets several Entra apps share one pool by listing each app's client ID.
  filter = "claims.tid == \"${var.entra_tenant_id}\" && claims.aud in [${join(", ", [for id in each.value.app_client_ids : "\"${id}\""])}]"
}

resource "confluent_role_binding" "workload" {
  for_each = local.all_bindings

  principal   = "User:${confluent_identity_pool.workload[each.value.workload].id}"
  role_name   = each.value.role
  crn_pattern = "${local.kafka_rb_crn_prefix}/${each.value.crn_suffix}"
}
