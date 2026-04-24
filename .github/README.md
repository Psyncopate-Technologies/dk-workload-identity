# .github/

GitHub Actions workflows that apply the `terraform/` tree to DKP's Confluent
Cloud organization.

| Workflow | Purpose | Trigger |
|---|---|---|
| `workflows/terraform-workload.yml`     | DKP-operated — runs `terragrunt <action>` against one stack under `terraform/live/`. | `workflow_dispatch` (pick `stack` + `action`) or PR plan on paths under `terraform/**` / `tools/**` |
| `workflows/terraform-poc-workload.yml` | Ayele-side PoC validation of the same stacks. DKP can delete after hand-off. | same shape |

Actions available: `plan` / `apply` / `destroy`. Pull-request runs always `plan`.

## What the workflow does per run

1. `actions/checkout@v4`
2. `azure/login@v2` — OIDC-federated to a pre-created Entra app (no stored secret).
3. `./tools/install.sh` — downloads pinned Terraform, Terragrunt, Confluent CLI, Python 3.12 into `tools/bin/`.
4. `terragrunt init` in the chosen stack.
5. `terragrunt <action>`.

## Secrets it expects

Set these at repo → Settings → Secrets and variables → Actions:

| Name | Source |
|---|---|
| `AZURE_CLIENT_ID`           | Entra app registration set up for OIDC federation (Application Administrator in DKP) |
| `AZURE_TENANT_ID`           | DKP Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID`     | Azure subscription hosting the Terraform state storage account |
| `CONFLUENT_CLOUD_API_KEY`   | Confluent Cloud Cloud API key with `OrganizationAdmin` |
| `CONFLUENT_CLOUD_API_SECRET`| Matching secret |

## RBAC the federated app needs

- `Storage Blob Data Contributor` on the tfstate storage account
- No Azure resource creation scope needed (the DKP-shipped workflow only touches Confluent Cloud)

See `CHECKLIST.md` for the exact `az` commands to set this up in DKP's Azure tenant.
