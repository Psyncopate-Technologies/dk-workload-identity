# .github/

GitHub-side config for this repo — currently just the Actions workflow under `workflows/`.

| File | Workflow name | What it does |
|---|---|---|
| `workflows/terraform-workload.yml` | `terraform-workload` | Applies `terraform/live/<stack>` against DKP's Confluent org + Azure subscription. Workload-identity auth (GitHub OIDC → User-Assigned Managed Identity) — no long-lived service-principal password. |

The workflow:
- triggers on `workflow_dispatch` (pick `stack` + `action`) and on PRs touching `terraform/**`, `tools/**`, or itself;
- installs pinned CLIs via `./tools/install.sh`;
- reads remote state from Azure Storage via the `azurerm` backend, auth via Azure AD.

## Repository secrets — name + value

Set at **repo → Settings → Secrets and variables → Actions → Repository secrets**.

| Name                         | Value                                  | Notes |
|---|---|---|
| `AZURE_CLIENT_ID`            | `6b876d61-66e1-46d9-bb1f-c783d9dc0295` | Client ID of the User-Assigned Managed Identity the runner authenticates as (GitHub OIDC → Azure workload identity federation). |
| `AZURE_TENANT_ID`            | `7bab0bc1-bb61-48d7-b2d4-79825c2ac6b8` | Entra tenant the UMI and Confluent identity provider live in. |
| `AZURE_SUBSCRIPTION_ID`      | `e2a01c39-dfaa-40e2-84bc-133e0fa5d21e` | Subscription that hosts the Terraform state storage account and the Confluent admin Key Vault. |
| `TG_STATE_STORAGE_ACCOUNT`   | `saze1devconfluent`                    | Azure Storage account holding the remote `terraform.tfstate` blobs. |
| `TG_STATE_CONTAINER`         | `confluent`                            | Blob container inside the storage account where state blobs live. |
| `TG_STATE_RESOURCE_GROUP`    | `RG-ze1-DEV-Engineering-confluent`     | Resource group containing `saze1devconfluent` — needed by the `azurerm` backend to locate the SA. |

The Confluent admin API key + secret are **not** stored in GitHub. Terraform pulls them from Azure Key Vault at plan/apply time from the two secrets `confluent-admin-key` and `confluent-admin-secret` (DKP convention).

## Repository variables

Set at **repo → Settings → Secrets and variables → Actions → Variables**. Vault identifiers aren't secrets, so they go here rather than in the secrets section.

| Name                                  | Value              | Notes |
|---|---|---|
| `AZURE_KEY_VAULT_NAME`                | `kv-ze1-dev-confluent-gm6` | Key Vault holding the Confluent admin API key + secret (`confluent-admin-key`, `confluent-admin-secret`). |
| `AZURE_KEY_VAULT_RESOURCE_GROUP_NAME` | *<confirm with Rukai>*     | Resource group that holds the Key Vault above. Likely `RG-ze1-DEV-Engineering-confluent` (same RG as the tfstate SA); verify with `az keyvault show --name kv-ze1-dev-confluent-gm6 --query resourceGroup -o tsv`. |

## RBAC the federated identity needs

UMI `principal_id = fa9be012-9716-446d-a384-877cfdbd8773`:

- `Storage Blob Data Contributor` on `saze1devconfluent` (tfstate SA).
- `Key Vault Secrets User` on the Key Vault named in `AZURE_KEY_VAULT_NAME` — lets Terraform read `confluent-admin-key` + `confluent-admin-secret`. (If DKP uses legacy Access Policies instead of RBAC, grant `Get` on secrets.)
- No Azure resource creation scope needed — the workflow doesn't create Azure resources.

See `CHECKLIST.md` §3 for bootstrap commands.

## Local CLI equivalent

From the repo root:

```bash
set -a; source .env; set +a
source tools/env.sh
cd terraform/live/<stack>
terragrunt init && terragrunt plan
```
