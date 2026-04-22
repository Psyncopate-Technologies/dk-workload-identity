# Project Guidelines — DK Workload Identity

## Goal

Stand up **workload identity in Confluent Cloud** for DKP, federated with Microsoft Entra ID, so Kafka clients (Azure-native and on-prem) authenticate with Entra-issued tokens instead of static API keys.

## Stakeholders

- **Customer (client):** DKP
- **DKP lead engineer / Kafka administrator:** Rukai Lou — primary contact on anything Kafka / Confluent on DKP's side.
- **Azure partners (cloud team):** Dov Goldman, Willy Marescot — own anything cloud/Azure on DKP's side.
- **Implementer:** Ayele (Confluent PS) — builds in his development Confluent Cloud org + Azure tenant, then hands off.

## Environments & clusters

DKP's production layout (from their Confluent Console):

| DKP env | Kafka clusters | Used for |
|---|---|---|
| `DKP-AZ1-STREAMING-MESH` (eastus) | `kafka-ze1-nonprod-enterprise-dse` (lkc-1o1jkv) | DEV, UAT |
| | `kafka-ze1-prod-enterprise-zie` (lkc-wxdwk9) | PRD |

One PrivateLink Attachment gateway (`DKP-AZ1-PROD-PVTLINK-GATEWAY`, platt-7997kw) serves both clusters, with two access points (`DKP-AZ1-NONPROD-ACCESSPOINT`, `DKP-AZ1-PROD-ACCESSPOINT`). DNS domain: `eastus.azure.private.confluent.cloud`.

DKP has **one** identity provider registered in their Confluent org (`DKP Entra ID`) and manages identity pools on top of it.

Logical env slugs used in this repo: `dev`, `uat`, `prd` (not `prod`).

## Code split — what ships to DK vs what stays internal

| Tree | Ships to DK? | What it provisions |
|---|---|---|
| `terraform/` | **Yes** | Confluent-Cloud workload identity: identity provider (org-level), identity pools, role bindings |
| `powershell/` (future) | **Yes** | Entra ID app registrations, Expose-an-API scopes, federated credentials |
| `poc-infra/` | **No — internal only** | Azure VNets + Confluent env/clusters/PrivateLink for Ayele's PoC (mirrors DKP's layout) |

**DK already has** their identity provider + environment + clusters + PrivateLink wired up. For DK's deployment they'll skip `terraform/live/_org/` and pass their existing `identity_provider_id` as a Terragrunt input override. `poc-infra/` is only so Ayele can validate the full chain end-to-end in his own org before delivery.

## Split of responsibilities (language)

| Side | Tooling |
|---|---|
| **Azure / Entra** (app registrations, federated credentials, API scopes) | **PowerShell** scripts |
| **Confluent Cloud** (identity provider, identity pools, role bindings, PrivateLink) | **Terraform** (via Terragrunt) |
| **Azure network** (VNets, subnets, Private Endpoints, Private DNS) — PoC only | **Terraform** (`poc-infra/`) |

Do not put Azure-identity resource creation into Terraform, and do not put Confluent resources into PowerShell.

## Naming convention

All workload-identity pool display names follow:

```
dk-confluent-{env}-{domain}-{workload}
```

- `{env}` ∈ {dev, uat, prd} — the stack directory under `terraform/live/`.
- `{domain}-{workload}` — the key in the `workloads` map input (e.g. `mergerarb-madam`).

Example: `mergerarb-madam` in env `dev` → pool display name `dk-confluent-dev-mergerarb-madam`.

PoC Azure/Confluent resources use prefix `dk-confluent-poc` to stay clearly separate.

## Parametrization

**Everything must be parametrized** — no hardcoded tenant IDs, env IDs, cluster IDs, app client IDs, topic prefixes, or region names. Use Terragrunt inputs for Terraform and script parameters/env vars for PowerShell. If the same value appears in two places, it belongs in one variable.

## Credentials & secrets

- **Never commit secrets.** Sensitive values go in `.env` at the repo root (gitignored).
- **Local runs** source credentials from `.env` — Terraform picks them up via `TF_VAR_*` env vars; PowerShell reads from the process environment.
- **Pipeline runs** use **GitHub Actions repo secrets**. Whenever I introduce a new secret, I will **explicitly call out** the secret name to create in GitHub → Settings → Secrets and variables → Actions before the pipeline will work.
- **GitHub repo secrets (both workflows):**
  - `AZURE_CLIENT_ID` = `f06375c6-df02-4309-9588-3c1ae9d2c404` (Entra app `dk-confluent-poc-gh-actions`)
  - `AZURE_TENANT_ID` = `1b9dca15-4db4-4905-8725-d318d11c6875`
  - `AZURE_SUBSCRIPTION_ID` = `e2fc4b68-6dd0-4c89-99c6-d6b16f9a0eba`
  - `CONFLUENT_CLOUD_API_KEY` = Org key from `Day-2/credentials/api-keys.env`
  - `CONFLUENT_CLOUD_API_SECRET` = matching secret
- **GH OIDC federated creds** on the Entra app: `ref:refs/heads/main` and `pull_request` (bootstrap script: [`poc-infra/scripts/bootstrap-gh-oidc.sh`](poc-infra/scripts/bootstrap-gh-oidc.sh)).
- **RBAC already granted** to the app's service principal: `Storage Blob Data Contributor` on the tfstate SA, `Contributor` on the PoC subscription.
- **Development credentials** (Confluent Cloud Org + cluster admin keys) live at:
  `/Users/ayeleadmassu/Documents/Confluent-PS/DKP/engagment-2/Day-2/credentials`
- **Azure Tenant ID** (Ayele's dev tenant): `1b9dca15-4db4-4905-8725-d318d11c6875`.
- **Azure Subscription ID** (PoC — where `poc-infra/` lands): `e2fc4b68-6dd0-4c89-99c6-d6b16f9a0eba`.
  Ayele logs into Azure via browser; Terraform/PowerShell picks up the CLI session. Do not ask for or store Azure credentials.

## State backend — Azure Storage

Both Terragrunt trees use an `azurerm` remote backend:

| | |
|---|---|
| Resource group | `rg-dk-confluent-poc-tfstate` |
| Storage account | `dkconfluentpoctfstate` |
| Container | `tfstate` |
| Key layout | `<tree>/<stack>/terraform.tfstate` (e.g. `poc-infra/azure-network/terraform.tfstate`) |
| Auth | Azure AD (`use_azuread_auth = true`). Local runs use the signed-in `az` CLI session; CI uses GitHub OIDC → federated Entra app. |

RBAC: the principal running terragrunt (user locally, federated identity in CI) needs **Storage Blob Data Contributor** on the storage account. Ayele's user is already granted.

Backend config is overridable via env vars — DK overrides these for their own tenant/account without editing `root.hcl`:

- `TG_STATE_RESOURCE_GROUP`, `TG_STATE_STORAGE_ACCOUNT`, `TG_STATE_CONTAINER`
- `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`

## Tooling — bring-your-own, do not assume pre-installed

The build agent is a **freely-provisioned GitHub-hosted runner** and assumes nothing is pre-installed. Tool set may evolve as DKP dictates.

Pinned local copies live under `tools/`:

- Terraform, Terragrunt, Confluent CLI, Python 3.12 (via uv)

The `tools/` folder is the single source of truth for versions. The GitHub Actions pipelines install from `tools/install.sh` onto the build agent. Local development uses the same copies — no `brew install`, no system-wide installs.

Pin versions explicitly in `tools/versions.env`. When DKP asks to upgrade, update versions and push.

## GitHub Actions — deployment

Two workflows, one per tree, so DK-shipped and PoC-internal changes have separate triggers and audit trails:

- `.github/workflows/terraform-workload.yml` — applies `terraform/live/<stack>` (stack = `_org` | `dev` | `uat` | `prd`)
- `.github/workflows/terraform-poc-infra.yml` — applies `poc-infra/live/<stack>` (stack = `azure-network` | `confluent-platform` | `azure-private-endpoints`)

Both are `workflow_dispatch` with `plan` | `apply` | `destroy` as options. PR runs always `plan` only.

## Git workflow

- **Push after every meaningful change.** Do not leave local-only commits.
- **Commit messages:** brief, imperative ("Add federated credential script", "Parametrize cluster id"). One-line subject, optional body only when the "why" is non-obvious.
- **Never add Claude as a co-author.** No `Co-Authored-By: Claude ...` trailer on any commit.
- Push to the current working branch (default `main` unless a feature branch is in play). Ask before force-pushing or rewriting history.

## Out-of-scope (for now)

- Creating the business topics themselves — the Terraform only manages RBAC on the configured prefixes.
- Client application code — only the identity plumbing.
- Cluster-link / Connector / ksqlDB infrastructure.
