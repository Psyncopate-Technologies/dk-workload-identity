# terraform/live/

Per-stack Terragrunt configs. Apply order: `_org` → `dev` → `uat` → `prd`.

| Stack | Purpose | Reads |
|---|---|---|
| `_org/` | Creates the org-level `confluent_identity_provider` (one per Entra tenant). Skip if DKP already has one. | — |
| `dev/`  | Per-workload identity pools + RBAC for the **dev** logical env. Maps to DKP's nonprod cluster. | `dev/workloads.json` |
| `uat/`  | Same for **uat** (also nonprod cluster). | `uat/workloads.json` |
| `prd/`  | Same for **prd** (prod cluster). | `prd/workloads.json` |

## State backend

`root.hcl` uses `azurerm` remote state. Overridable via env vars
(`TG_STATE_RESOURCE_GROUP`, `TG_STATE_STORAGE_ACCOUNT`, `TG_STATE_CONTAINER`,
`ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`) so DKP plugs in their own storage
account without editing HCL.

## Typical DKP flow

```bash
set -a; source ../../.env; set +a

cd _org && terragrunt apply        # skip if DKP's provider already exists; then override identity_provider_id per-env
cd ../dev && terragrunt apply
cd ../uat && terragrunt apply
cd ../prd && terragrunt apply
```

In practice DKP runs `.github/workflows/terraform-workload.yml` (workflow_dispatch, pick stack + action) rather than the CLI.
