# .github/workflows/

| File | Workflow name | Owner | What it does |
|---|---|---|---|
| `terraform-workload.yml`     | `terraform-workload`     | DKP                  | Primary workflow. Applies `terraform/live/<stack>` against **DKP's** Confluent org + Azure subscription. Workload-identity auth (GitHub OIDC → DKP Entra federated app) — no long-lived service-principal password. |
| `terraform-poc-workload.yml` | `terraform-poc-workload` | Confluent PS (Ayele) | Same code, targeted at Ayele's PoC Confluent org + Azure subscription for pre-delivery validation. DKP can delete this file after hand-off. |
| `terraform-poc-infra.yml`    | `terraform-poc-infra`    | Confluent PS (Ayele) | Applies the PoC-only Azure network + Confluent env/cluster/PrivateLink (`poc-infra/` tree, not shipped to DKP). |

All three workflows:
- trigger on `workflow_dispatch` (pick `stack` + `action`) and on PRs touching their scope;
- install pinned CLIs via `./tools/install.sh`;
- read remote state from Azure Storage via `azurerm` backend, auth via Azure AD.

## Secrets the workflows expect

The two `terraform-workload*` workflows share the same secret names. On DKP's side, point the secrets at DKP's identities / resources; on Ayele's PoC side, at Ayele's.

| Secret | Used for |
|---|---|
| `AZURE_CLIENT_ID`            | Federated Entra app (OIDC) the runner authenticates as |
| `AZURE_TENANT_ID`            | Entra tenant |
| `AZURE_SUBSCRIPTION_ID`      | Subscription hosting the Terraform state storage account |
| `CONFLUENT_CLOUD_API_KEY`    | Cloud API key with `OrganizationAdmin` in the target Confluent org |
| `CONFLUENT_CLOUD_API_SECRET` | Matching secret |
| `TG_STATE_RESOURCE_GROUP`    | (DKP workflow) override the state RG in `terraform/live/root.hcl` |
| `TG_STATE_STORAGE_ACCOUNT`   | ditto — storage account |
| `TG_STATE_CONTAINER`         | ditto — container |

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
