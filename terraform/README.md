# Confluent Cloud × Microsoft Entra ID OIDC — Terraform / Terragrunt

This is the **code we ship to DK**. It provisions the Confluent-Cloud side of
the workload-identity OIDC flow:

- 1 org-level `confluent_identity_provider` pointed at the Entra tenant (PoC only — DK already has their own)
- 1 `confluent_identity_pool` per workload in each env (`dk-confluent-{env}-{domain}-{workload}`)
- Per-workload `confluent_role_binding`s (DeveloperWrite / DeveloperRead on topic + group prefixes)

The **Entra** side (app registrations, Expose-an-API scope, federated credentials)
is created by the PowerShell scripts under `../powershell/` (separate deliverable).

## Layout

```
terraform/
├── modules/
│   ├── confluent-identity-provider/   # org-level — one per Entra tenant
│   └── confluent-workload-pools/      # per-env — pools + role bindings for a map of workloads
└── live/
    ├── root.hcl                       # provider + (local, for now) state backend
    ├── _org/terragrunt.hcl            # creates the identity provider (PoC only — DK already has theirs)
    ├── dev/terragrunt.hcl
    ├── uat/terragrunt.hcl
    └── prd/terragrunt.hcl
```

Per-env stacks take `identity_provider_id` as a Terragrunt `dependency` on the
`_org` stack. When DK runs this in their own org, they skip `_org` and override
`identity_provider_id` with their existing provider's ID.

## Naming convention

All pool display names follow:

```
dk-confluent-{env}-{domain}-{workload}
```

`{env}` is the stack directory (`dev`, `uat`, `prd`). `{domain}-{workload}` is
the key in the `workloads` map. Example: `mergerarb-madam` in `dev` →
`dk-confluent-dev-mergerarb-madam`.

## Versions

Pinned in [`../tools/versions.env`](../tools/versions.env). Run `./tools/install.sh`
from the repo root and `source ./tools/env.sh` before any terragrunt command.

## Prerequisites

1. **Confluent Cloud API key** with `OrganizationAdmin` role. Exported via `TF_VAR_confluent_cloud_api_key` / `TF_VAR_confluent_cloud_api_secret`.
2. Per env, have these ready:
   - Entra tenant ID (issuer + JWKS derived from it)
   - Confluent environment ID (`env-*`) and Kafka cluster ID (`lkc-*`)
   - One Entra app registration per workload (the `app_client_id` in the `workloads` map)

## Secrets

Copy `.env.example` at the repo root to `.env`, fill in, and source before running:

```bash
set -a; source ../../.env; set +a   # from terraform/live/<env>/
```

`.env` is gitignored. CI reads the same values from GitHub repo secrets.

## Running locally

```bash
cd terraform/live/_org       # first — creates the identity provider
terragrunt apply

cd ../dev                    # then — per-env pools
terragrunt apply
terragrunt output            # pool IDs + display names for client SASL config
```

State is local for now (`terraform/live/<stack>/terraform.tfstate`). Moving to
Azure Storage before we apply via GitHub Actions at scale — see CLAUDE.md.

## Running in CI

Workflow: `.github/workflows/terraform-workload.yml` (`workflow_dispatch`).
Pick the env and action (`plan` / `apply` / `destroy`). Requires GitHub secrets
`CONFLUENT_CLOUD_API_KEY` and `CONFLUENT_CLOUD_API_SECRET`.

## Outputs

Per env stack:

| Output | Use |
|---|---|
| `identity_pool_ids` | `{ workload_key -> pool-* }` — plug into client SASL (`extension_identityPoolId`) |
| `identity_pool_names` | `{ workload_key -> dk-confluent-<env>-<key> }` — cross-check in Console |
| `identity_pool_filters` | `{ workload_key -> filter expr }` — debug with a decoded JWT at jwt.ms |

## Handing off to DK

What DK runs on their side:

1. PowerShell scripts (under `../powershell/`) — create Entra app registrations.
2. `terraform/live/<env>/terragrunt.hcl` with their own values + their existing `identity_provider_id`.
3. They skip `_org/` (their identity provider is already wired up).
