# .github/workflows/

| File | Workflow name | Owner | What it does |
|---|---|---|---|
| `terraform-workload.yml`     | `terraform-workload`     | Confluent PS (Ayele) | Applies `terraform/live/<stack>` against the **Confluent PS** PoC Confluent org + Azure subscription. Used to validate the code before hand-off. |
| `terraform-workload-dkp.yml` | `terraform-workload-dkp` | DKP                  | Same mechanics, but scoped to **DKP's** Confluent org + Azure subscription. Workload-identity auth (GitHub OIDC → DKP Entra federated app) — no long-lived service-principal password. |

Both workflows:
- trigger on `workflow_dispatch` (pick `stack` + `action`) and on PRs touching `terraform/**` / `tools/**`;
- install pinned CLIs via `./tools/install.sh`;
- read remote state from Azure Storage via `azurerm` backend, auth via Azure AD.

## Secrets each workflow expects

Both workflows read the same secret names. On DKP's side, point the secrets at DKP's identities/resources:

| Secret | Used for |
|---|---|
| `AZURE_CLIENT_ID`            | Federated Entra app (OIDC) the runner authenticates as |
| `AZURE_TENANT_ID`            | DKP Entra tenant |
| `AZURE_SUBSCRIPTION_ID`      | Subscription hosting the Terraform state storage account |
| `CONFLUENT_CLOUD_API_KEY`    | Cloud API key with `OrganizationAdmin` in DKP's Confluent org |
| `CONFLUENT_CLOUD_API_SECRET` | Matching secret |
| `TG_STATE_RESOURCE_GROUP`    | (DKP workflow only, if you override state defaults) |
| `TG_STATE_STORAGE_ACCOUNT`   | ditto |
| `TG_STATE_CONTAINER`         | ditto |

## RBAC the federated app needs (DKP)

- `Storage Blob Data Contributor` on the tfstate storage account.
- No Azure resource creation scope needed — the workflow only touches Confluent Cloud + Azure Storage state.

See `CHECKLIST.md` §3 for the bootstrap commands.

## Local CLI equivalent

```bash
set -a; source ../../.env; set +a
source tools/env.sh
cd terraform/live/<stack>
terragrunt init && terragrunt plan
```
