# Confluent Cloud × Microsoft Entra ID OIDC — Terraform / Terragrunt

This stack provisions the **Confluent Cloud** side of a workload-identity OIDC flow:

- 1 `confluent_identity_provider` pointed at a Microsoft Entra tenant
- 2 `confluent_identity_pool`s — `producer` and `consumer` — filtered by `claims.tid` and `claims.aud`
- 3 `confluent_role_binding`s — `DeveloperWrite` on topic prefix for the producer, `DeveloperRead` on topic + consumer-group prefix for the consumer

The **Entra** side (app registrations, Expose-an-API scope, client secrets) is managed manually out-of-band.

## Layout

```
terraform/
├── modules/
│   └── confluent-oidc/        # reusable module
└── live/
    ├── root.hcl               # root: provider, versions, local state
    ├── dev/terragrunt.hcl     # env-1y1176 / lkc-x9qrwg
    ├── uat/terragrunt.hcl     # placeholders — fill in before use
    └── prod/terragrunt.hcl    # placeholders — fill in before use
```

## Versions

- Terraform `~> 1.9`
- Terragrunt `~> 0.66`
- `confluentinc/confluent` provider `~> 2.10`

## Prerequisites

1. **Confluent Cloud Cloud API key** with the `OrganizationAdmin` role (needed to create identity providers, identity pools, and role bindings). Create via Confluent Cloud Console → *Administration → API keys → Cloud resource management*.
2. For each environment, have these Entra facts ready:
   - Tenant ID
   - Issuer URL (typically `https://login.microsoftonline.com/<tenant_id>/v2.0`)
   - JWKS URI (typically `https://login.microsoftonline.com/<tenant_id>/discovery/v2.0/keys`)
   - Producer app registration **client ID**
   - Consumer app registration **client ID**
3. The Confluent Environment ID (`env-*`) and Kafka Cluster ID (`lkc-*`) already exist.

## Secrets — how they're passed in

The Confluent Cloud API key/secret is **not committed**. Terraform reads it from environment variables using the built-in `TF_VAR_<name>` convention.

```bash
export TF_VAR_confluent_cloud_api_key="CKXXXXXXXXXXXXXX"
export TF_VAR_confluent_cloud_api_secret="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Those env vars get picked up as `var.confluent_cloud_api_key` / `var.confluent_cloud_api_secret` inside the generated `provider.tf`. They must be set in the shell each time you run Terragrunt (or put them in a gitignored `.envrc` used with `direnv`).

Everything else (tenant IDs, cluster IDs, app-client IDs) lives in the per-env `terragrunt.hcl` files — replace the `REPLACE_WITH_*` placeholders before running.

## Running

From any env directory:

```bash
cd terraform/live/dev

# init — downloads provider, generates provider.tf/backend.tf
terragrunt init

# preview
terragrunt plan

# apply
terragrunt apply

# show outputs (pool IDs you will wire into your Java clients)
terragrunt output
```

State for each env is stored **locally** at `terraform/live/<env>/terraform.tfstate` (per the `remote_state { backend = "local" }` block in `live/root.hcl`).

## Outputs

After apply, each env exposes:

| Output | Use |
|---|---|
| `identity_provider_id` | For verification in Confluent Console |
| `producer_identity_pool_id` | `pool-xxxx` — put in producer Java client's SASL config (`extension_logicalCluster`/`extension_identityPoolId`) |
| `consumer_identity_pool_id` | `pool-xxxx` — put in consumer Java client's SASL config |
| `producer_pool_filter` | sanity-check the `claims.tid`/`claims.aud` expression |
| `consumer_pool_filter` | same |

## Identity pool filter shape

For each pool: `claims.tid == "<entra_tenant_id>" && claims.aud == "api://<app_client_id>"`

`identity_claim` is fixed to `claims.sub` for both pools (per project convention).

## RBAC summary

| Pool | Role | Scope |
|---|---|---|
| producer | `DeveloperWrite` | topic `dkp*` |
| consumer | `DeveloperRead` | topic `dkp*` |
| consumer | `DeveloperRead` | group `dkp*` |

Topic/group prefix is `dkp` across **all** envs (not env-scoped).

## Destroying

```bash
cd terraform/live/dev
terragrunt destroy
```

## Troubleshooting

- **401/403 on apply** — the Cloud API key either lacks `OrganizationAdmin` or the key/secret env vars aren't exported in the current shell. Re-run `env | grep TF_VAR_`.
- **`terragrunt` can't find the module** — run from `terraform/live/<env>/`, not from `terraform/live/`.
- **Filter tests failing on the Confluent side** — decode a real token at jwt.ms and confirm `tid`, `aud`, and `sub` match what the pool filter expects.
