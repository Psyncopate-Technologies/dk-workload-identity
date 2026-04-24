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

### `terraform-workload.yml`

| Name                         | Value                                  | Notes |
|---|---|---|
| `AZURE_CLIENT_ID`            | `6b876d61-66e1-46d9-bb1f-c783d9dc0295` | Client ID of the User-Assigned Managed Identity the runner authenticates as (GitHub OIDC → Azure workload identity federation). |
| `AZURE_TENANT_ID`            | `7bab0bc1-bb61-48d7-b2d4-79825c2ac6b8` | Entra tenant the UMI and Confluent identity provider live in. |
| `AZURE_SUBSCRIPTION_ID`      | `e2a01c39-dfaa-40e2-84bc-133e0fa5d21e` | Subscription that hosts the Terraform state storage account. |
| `CONFLUENT_CLOUD_API_KEY`    | *<ask Rukai>*                          | Confluent Cloud API key with `OrganizationAdmin` role on the Confluent org — lets Terraform create identity providers, pools, and role bindings. |
| `CONFLUENT_CLOUD_API_SECRET` | *<ask Rukai>*                          | Secret paired with the API key above. |
| `TG_STATE_STORAGE_ACCOUNT`   | `saze1devconfluent`                    | Azure Storage account holding the remote `terraform.tfstate` blobs. |
| `TG_STATE_CONTAINER`         | `confluent`                            | Blob container inside the storage account where state blobs live. |
| `TG_STATE_RESOURCE_GROUP`    | *<ask Dov/Willy>*                      | Resource group containing `saze1devconfluent` — needed by the `azurerm` backend to locate the SA. |

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
