# terraform/ — Confluent Cloud workload identity (Terragrunt)

Provisions the Confluent-Cloud side of DKP's workload identity:

- **One organization-level identity provider** (`op-*`) pointed at the DKP Entra tenant — created by `live/_org/`.
- **Per-env stacks** (`live/dev`, `live/uat`, `live/prd`) each reading a local `workloads.json`:
  - One `confluent_identity_pool` per workload (filtered on Entra `claims.tid` + `claims.aud`).
  - Role bindings per workload: DeveloperWrite / DeveloperRead / DeveloperManage on topic prefixes or exact topic names; DeveloperRead on consumer-group prefixes or names.

The **Entra side** (app registrations, Expose-an-API scope, token v2, optional federated credentials) is handled by `../powershell/` or the manual portal runbook under `../docs/`.

## Layout

```
terraform/
├── modules/
│   ├── confluent-identity-provider/   # one resource — the OIDC trust anchor (org-scoped)
│   └── confluent-workload-pools/      # pools + role bindings for a map of workloads
└── live/
    ├── root.hcl                       # Azure Storage remote state + provider config
    ├── _org/                          # creates the identity provider (skip if DKP already has one)
    ├── dev/ (terragrunt.hcl + workloads.json)
    ├── uat/ (terragrunt.hcl + workloads.json)
    └── prd/ (terragrunt.hcl + workloads.json)
```

## workloads.json shape

```json
{
  "entra_tenant_id":           "...",
  "confluent_organization_id": "...",
  "confluent_environment_id":  "env-xxxxxx",
  "kafka_cluster_id":          "lkc-xxxxxx",
  "workloads": {
    "<domain>-<workload>": {
      "description":             "...",
      "app_client_id":           "<Entra Application (client) ID>",
      "write_topic_prefixes":    ["dev.transaction.oms."],
      "write_topic_names":       ["dev.deal.calc.mergerarb.json"],
      "read_topic_prefixes":     ["dev.deal."],
      "read_topic_names":        [],
      "manage_topic_prefixes":   [],
      "manage_topic_names":      [],
      "consumer_group_prefixes": ["dk-confluent-dev-position-reader-"],
      "consumer_group_names":    []
    }
  }
}
```

Fields:
- `*_prefixes` — matched with trailing `*` (CRN `topic=<prefix>*`).
- `*_names`    — matched exactly (CRN `topic=<name>`).
- Any list defaults to empty; omit fields that don't apply.
- `app_client_id` is the Entra Application (client) ID (GUID) — not the `api://…` URI. v2 tokens emit the bare GUID as the `aud` claim, which is what the pool filter expects.

## Versions

Pinned in [`../tools/versions.env`](../tools/versions.env). Run `./tools/install.sh` from the repo root and `source ./tools/env.sh` before any terragrunt command.

## Prerequisites

1. **Confluent Cloud API key** with `OrganizationAdmin` role.
   Exported as `TF_VAR_confluent_cloud_api_key` / `TF_VAR_confluent_cloud_api_secret`.
2. Per env: finalized `workloads.json` (replace every `REPLACE_WITH_…` placeholder).
3. Azure auth in the shell running terragrunt (for the remote state backend) — either `az login` locally or OIDC federated credential in CI.

## Apply order

```bash
set -a; source ../../.env; set +a      # from terraform/live/<env>/

cd terraform/live/_org && terragrunt apply   # once per tenant
cd ../dev              && terragrunt apply
cd ../uat              && terragrunt apply
cd ../prd              && terragrunt apply
```

Per-env stacks depend on `_org` via a Terragrunt `dependency` block; they pull the `identity_provider_id` from `_org`'s output.

If DKP already has the identity provider, skip `_org` and override `identity_provider_id` via a terragrunt input or a small edit to the per-env `dependency` block.

## Outputs per env stack

| Output | Use |
|---|---|
| `identity_pool_ids`     | `{ workload_key → pool-* }` — plug into client SASL `extension_identityPoolId` |
| `identity_pool_names`   | `{ workload_key → dk-confluent-<env>-<key> }` — cross-check in Console |
| `identity_pool_filters` | `{ workload_key → filter expression }` — debug with a decoded JWT at jwt.ms |

## Handing off to DK

1. Entra admin creates app registrations via `docs/DK-Confluent-Entra-App-Runbook.docx` + `docs/app-registrations.xlsx` (or via `powershell/scripts/New-WorkloadApps.ps1`).
2. Paste each Application (client) ID from the completed spreadsheet into `terraform/live/<env>/workloads.json`.
3. Trigger `.github/workflows/terraform-workload.yml` for `_org`, then `dev`, `uat`, `prd`.
