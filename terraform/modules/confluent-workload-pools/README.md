# confluent-workload-pools

For a given env + cluster, creates one `confluent_identity_pool` per workload
and every accompanying `confluent_role_binding` needed to grant the pool
read/write/manage on the topics and consumer groups DKP has assigned to that
workload.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `environment_name`          | string | — | `dev` / `uat` / `prd`. Used in pool display name. |
| `name_prefix`               | string | `"dk-confluent"` | Display-name prefix. |
| `identity_provider_id`      | string | — | `op-*` from the org-level provider module. |
| `entra_tenant_id`           | string | — | Used in the pool filter (`claims.tid == …`). |
| `confluent_organization_id` | string | — | Org UUID — used in role-binding CRNs. |
| `confluent_environment_id`  | string | — | `env-*` — scope for the cluster CRN. |
| `kafka_cluster_id`          | string | — | `lkc-*` — cluster the role bindings target. |
| `workloads`                 | map(object) | `{}` | See shape below. |

### `workloads` shape

```hcl
workloads = {
  "mergerarb-madam" = {
    app_client_id           = "72a90c20-…"                    # required
    description             = "Merger-Arb MADAM workload — dev."
    write_topic_prefixes    = ["dev.transaction.oms."]        # CRN topic=<prefix>*
    write_topic_names       = ["dev.deal.calc.mergerarb.json"] # CRN topic=<name>
    read_topic_prefixes     = ["dev.deal."]
    read_topic_names        = []
    manage_topic_prefixes   = ["dev.transaction.oms."]        # DeveloperManage → create/delete/alter
    manage_topic_names      = []
    consumer_group_prefixes = ["dk-confluent-dev-mergerarb-madam-"]
    consumer_group_names    = []
  }
}
```

- Every list is optional and defaults to empty.
- `*_prefixes` become CRN patterns like `topic=<prefix>*` (wildcard match).
- `*_names` become `topic=<name>` (exact match) — useful when DKP names individual topics rather than namespace prefixes.

## Outputs

| Name | Description |
|---|---|
| `identity_pool_ids`     | `{ workload_key → pool-* }` — use as `extension_identityPoolId` in client SASL config |
| `identity_pool_names`   | `{ workload_key → display name }` |
| `identity_pool_filters` | `{ workload_key → filter expression }` — cross-check against a decoded JWT at jwt.ms |

## Pool filter

`claims.tid == "<entra_tenant_id>" && claims.aud == "<app_client_id>"` where
`app_client_id` is the Entra Application (client) ID GUID. The `api://` prefix
is **not** used — v2 Entra tokens put the bare GUID in `aud`, so that is what
the filter matches against.

## RBAC mapping

| Workload field       | Role             | Topic / group scope |
|---|---|---|
| `write_topic_prefixes` / `write_topic_names`       | `DeveloperWrite`  | topic (prefix or exact) |
| `read_topic_prefixes` / `read_topic_names`         | `DeveloperRead`   | topic (prefix or exact) |
| `manage_topic_prefixes` / `manage_topic_names`     | `DeveloperManage` | topic — grants create/delete/alter |
| `consumer_group_prefixes` / `consumer_group_names` | `DeveloperRead`   | consumer group (prefix or exact) |
