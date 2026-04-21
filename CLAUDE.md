# Project Guidelines — DK Workload Identity

## Goal

Stand up **workload identity in Confluent Cloud** for DKP, federated with Microsoft Entra ID, so Kafka clients (Azure-native and on-prem) authenticate with Entra-issued tokens instead of static API keys.

## Stakeholders

- **Customer (client):** DKP
- **DKP lead engineer / Kafka administrator:** Rukai Lou — primary contact on anything Kafka / Confluent on DKP's side.
- **Azure partners (cloud team):** Dov Goldman, Willy Marescot — own anything cloud/Azure on DKP's side.
- **Implementer:** Ayele (Confluent PS) — builds in his development Confluent Cloud org, then hands off.

## Environments & clusters

DKP operates **two Kafka clusters**:

| Cluster | Used for |
|---|---|
| `nonprod` | DEV, UAT |
| `prod` | PRD |

Mirror the same arrangement in Ayele's Confluent Cloud dev org for validation. All three logical envs (`dev`, `uat`, `prod`) already have terragrunt stacks under `terraform/live/`.

## Split of responsibilities

| Side | Tooling |
|---|---|
| **Azure / Entra** (app registrations, federated credentials, API scopes) | **PowerShell** scripts |
| **Confluent Cloud** (identity provider, identity pools, role bindings, private link) | **Terraform** (via Terragrunt) |

Do not put Azure resource creation into Terraform, and do not put Confluent Cloud resources into PowerShell.

## Parametrization

**Everything must be parametrized** — no hardcoded tenant IDs, env IDs, cluster IDs, app client IDs, topic prefixes, or region names. Use Terragrunt inputs for Terraform and script parameters/env vars for PowerShell. If the same value appears in two places, it belongs in one variable.

## Credentials & secrets

- **Never commit secrets.** Sensitive values (Confluent Cloud API key/secret, Azure client secrets, any other credentials) go in a `.env` file that is **gitignored**.
- **Local runs** source credentials from `.env` — Terraform picks them up via `TF_VAR_*` env vars; PowerShell reads from the process environment.
- **Pipeline runs** use **GitHub Actions repo secrets**. Whenever I introduce a new secret, I will **explicitly call out** the secret name to create in GitHub → Settings → Secrets and variables → Actions before the pipeline will work.
- **Development credentials** (Confluent Cloud Org Admin + Kafka cluster admin for Ayele's dev org) live at:
  `/Users/ayeleadmassu/Documents/Confluent-PS/DKP/engagment-2/Day-2/credentials`
  Ayele will share login details via `.env` — do not copy credentials into the repo.
- **Azure Tenant ID** (Ayele's dev tenant): `1b9dca15-4db4-4905-8725-d318d11c6875`.
  Ayele logs into Azure via browser; use his active session (e.g. `Connect-AzAccount` / `az login` already signed in) to create app registrations and federated identities. Do not ask for or store Azure credentials.

## Tooling — bring-your-own, do not assume pre-installed

The build agent is a **freely-provisioned GitHub-hosted runner** and assumes nothing is pre-installed. Tool set may evolve as DKP dictates.

Download **local copies** of the following into a top-level `tools/` folder:

- Terragrunt
- Terraform
- Python 3.12
- Confluent CLI

The `tools/` folder is the single source of truth for versions. The GitHub Actions pipeline installs from `tools/` onto the build agent. Local development uses the same copies — no `brew install`, no system-wide installs.

Pin versions explicitly. When DKP asks to upgrade, update `tools/` and the pipeline in the same PR.

## GitHub Actions — deployment

- All Terraform is deployed via **GitHub Actions workflows** — not from laptops. Local `terragrunt apply` is for development validation only.
- Workflow installs tools from `tools/` onto the runner.
- Secrets sourced from GitHub repo secrets (see above).
- One workflow per environment, or a single workflow parametrized on env — either is fine, but the env must be an explicit input.

## Private link (Confluent Cloud ↔ Azure)

Create a **private link** from the Confluent Cloud environment over to Azure so Kafka traffic does not traverse the public internet. Before I create it I will ask you for:

- Target Azure **region**
- Target Azure **VNet + subnet** (or at least the subscription + resource group where the Private Endpoint will land)
- Whether private link is needed for **both** clusters (`nonprod` and `prod`) or only `prod`
- Any existing Private DNS Zone configuration DKP wants reused

## Git workflow

- **Push after every meaningful change.** Do not leave local-only commits.
- **Commit messages:** brief, imperative ("Add federated credential script", "Parametrize cluster id"). One-line subject, optional body only when the "why" is non-obvious.
- **Never add Claude as a co-author.** No `Co-Authored-By: Claude ...` trailer on any commit.
- Push to the current working branch (default `main` unless a feature branch is in play). Ask before force-pushing or rewriting history.

## Out-of-scope (for now)

- Creating the Kafka clusters themselves — `env-*` and `lkc-*` are pre-existing inputs.
- Creating the business topics (e.g. `dkp_test`) — the Terraform only manages RBAC on the `dkp*` prefix.
- Client application code — only the identity plumbing.
