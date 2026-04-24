# .github/workflows/

| File | Workflow name | Owner | What it does |
|---|---|---|---|
| `terraform-workload.yml`     | `terraform-workload`     | DKP                  | Primary workflow. Applies `terraform/live/<stack>` against **DKP's** Confluent org + Azure subscription. Workload-identity auth (GitHub OIDC → DKP User-Assigned Managed Identity) — no long-lived service-principal password. |
| `terraform-poc-workload.yml` | `terraform-poc-workload` | Confluent PS (Ayele) | Same code, targeted at Ayele's PoC Confluent org + Azure subscription for pre-delivery validation. DKP can delete this file after hand-off. |
| `terraform-poc-infra.yml`    | `terraform-poc-infra`    | Confluent PS (Ayele) | Applies the PoC-only Azure network + Confluent env/cluster/PrivateLink (`poc-infra/` tree, not shipped to DKP). |

All three workflows:
- trigger on `workflow_dispatch` (pick `stack` + `action`) and on PRs touching their scope;
- install pinned CLIs via `./tools/install.sh`;
- read remote state from Azure Storage via `azurerm` backend, auth via Azure AD.

## Repository secrets — name + value

Set at **repo → Settings → Secrets and variables → Actions → Repository secrets**.

### DKP side — `terraform-workload.yml`

Provided by DKP (UMI: `uai-dev-sh17-cwi`, tfstate SA: `saze1devconfluent`):

| Name | Value |
|---|---|
| `AZURE_CLIENT_ID`            | `6b876d61-66e1-46d9-bb1f-c783d9dc0295` *(UMI client ID)* |
| `AZURE_TENANT_ID`            | `7bab0bc1-bb61-48d7-b2d4-79825c2ac6b8` *(DKP Entra tenant)* |
| `AZURE_SUBSCRIPTION_ID`      | `e2a01c39-dfaa-40e2-84bc-133e0fa5d21e` *(from the UMI's resource ID — verify the tfstate SA sits in this subscription too)* |
| `CONFLUENT_CLOUD_API_KEY`    | *(DKP Cloud API key with `OrganizationAdmin` — ask Rukai)* |
| `CONFLUENT_CLOUD_API_SECRET` | *(matching secret)* |
| `TG_STATE_STORAGE_ACCOUNT`   | `saze1devconfluent` |
| `TG_STATE_CONTAINER`         | `confluent` |
| `TG_STATE_RESOURCE_GROUP`    | *(RG that holds `saze1devconfluent` — ask Dov/Willy; `az storage account show --name saze1devconfluent --query resourceGroup -o tsv`)* |

### Confluent PS PoC side — `terraform-poc-workload.yml` + `terraform-poc-infra.yml`

Already wired up in this repo from the `bootstrap-gh-oidc.sh` run and the Day-2 credentials file:

| Name | Value |
|---|---|
| `AZURE_CLIENT_ID`            | `f06375c6-df02-4309-9588-3c1ae9d2c404` *(Entra app `dk-confluent-poc-gh-actions`)* |
| `AZURE_TENANT_ID`            | `1b9dca15-4db4-4905-8725-d318d11c6875` |
| `AZURE_SUBSCRIPTION_ID`      | `e2fc4b68-6dd0-4c89-99c6-d6b16f9a0eba` |
| `CONFLUENT_CLOUD_API_KEY`    | Org key from `Day-2/credentials/api-keys.env` (`CC_ORG_API_KEY`) |
| `CONFLUENT_CLOUD_API_SECRET` | Matching `CC_ORG_API_SECRET` |
| `TG_STATE_RESOURCE_GROUP` / `TG_STATE_STORAGE_ACCOUNT` / `TG_STATE_CONTAINER` | Not set — defaults in `terraform/live/root.hcl` (`rg-dk-confluent-poc-tfstate` / `dkconfluentpoctfstate` / `tfstate`) apply. |

## Repository variables

None required. All configuration is passed via the Repository secrets above, plus workflow-dispatch inputs (`stack`, `action`).

## RBAC the federated identity needs

**DKP UMI** (`principal_id = fa9be012-9716-446d-a384-877cfdbd8773`):

- `Storage Blob Data Contributor` on `saze1devconfluent` (tfstate SA).
- No Azure resource creation scope needed — the workflow only touches Confluent Cloud + Azure Storage state.

**PS Entra app** (`client_id = f06375c6-…`):
- `Storage Blob Data Contributor` on `dkconfluentpoctfstate`.
- `Contributor` on the PoC subscription (`terraform-poc-infra.yml` creates Azure VNets/VMs).

See `CHECKLIST.md` §3 for bootstrap commands.

## Local CLI equivalent

```bash
set -a; source ../../.env; set +a
source tools/env.sh
cd terraform/live/<stack>
terragrunt init && terragrunt plan
```
