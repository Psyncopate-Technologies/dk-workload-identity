# CHECKLIST — plumbing this repo into DKP's environment

Use this when physically moving the code from Ayele's laptop into DKP's git
and Azure/Confluent tenants. Every item below is either a **copy action**,
an **ask** (info/access needed from DKP), or a **provisioning step**.

Keep this file open alongside the repo — tick each box (`- [x]`) as you go.

---

## 0. What ships to DKP vs stays behind

**Ships to DKP:**

```
/                        (except files below)
├── CLAUDE.md            # optional — project guidelines, internal-facing
├── README.md
├── CHECKLIST.md         # this file
├── .env.example
├── .gitignore
├── terraform/
├── tools/
├── .github/
├── docs/
└── powershell/          # optional — automated alternative to the docx runbook
```

**Stays behind (do NOT copy):**

```
.env                     # gitignored anyway, but double-check
poc-infra/               # Ayele's PoC Azure + Confluent infra; not DKP's concern
tools/bin/               # gitignored; DKP re-runs tools/install.sh to repopulate
tools/.cache/ .python/
```

The `.gitignore` already excludes `.env`, `tools/bin/`, and state files, but
**do a clean copy** (e.g., `git archive`) so no cache artifacts slip through.

---

## 1. Physical hand-off

- [ ] **Clean clone** of `dk-workload-identity` into DKP's git platform (e.g. DKP GitHub/Azure DevOps). Remove `poc-infra/` before the first commit to DKP's repo.
- [ ] Confirm `.gitignore` is intact (especially `.env` and `tools/bin/` rules).
- [ ] Run `./tools/install.sh` once on a DKP-side workstation to verify tools download cleanly on the DKP network (some corp proxies block `github.com/releases`).

---

## 2. Facts to ASK from DKP team

Record the answers back into the repo before applying anything. Primary
contact: **Rukai Lou** (Kafka admin). Azure contacts: **Dov Goldman**, **Willy
Marescot**.

- [ ] **Confluent organization ID** (UUID). Not visible in the DKP console screenshots. → Rukai.
      Paste into `terraform/live/<env>/workloads.json` → `confluent_organization_id`.
- [ ] **Confluent environment ID** (`env-*`). Screenshots suggest `env-xx13z1`; **confirm**. → Rukai.
- [ ] **Kafka cluster IDs per env.** Screenshots suggest:
      - nonprod (covers dev + uat): `lkc-1o1jkv` (kafka-ze1-nonprod-enterprise-dse)
      - prod (covers prd):          `lkc-wxdwk9` (kafka-ze1-prod-enterprise-zie)
      **Confirm both.** → Rukai.
- [ ] **Existing identity provider ID** (`op-*`). DKP already has `DKP Entra ID` wired up. → Rukai or the Confluent Cloud console under Accounts & access → Workload identities.
      If supplied, the `terraform/live/_org/` stack is **not applied**; instead override
      `identity_provider_id` in each per-env stack (see `terraform/live/_org/README.md`).
- [ ] **prd topic list.** Rukai's topic list only covers dev/dev2/uat/uat2; prd topics not supplied. → Rukai.
      Paste into `terraform/live/prd/workloads.json` replacing every `REPLACE_WITH_PRD_*` placeholder.
- [ ] **ibconnect topics — prefix or exact match?** Rukai labelled them as "prefix" but the entries (`dev.ibconnect.streams.avro` etc.) don't end in a dot. Confirm whether DKP wants prefix-match (current: `write_topic_prefixes`) or exact-match (move to `write_topic_names`).
- [ ] **Workload display-name / domain-workload splits for non-mergerarb.** The only explicit naming Rukai has given us is `dk-confluent-{env}-mergerarb-madam`. The other four workloads use the hyphen split we proposed — please confirm:
      - `position-writer`, `position-reader`
      - `tft-writer`
      - `ibconnect-connector`

---

## 3. Azure bootstrap in DKP's tenant

Needed so the `terraform-workload.yml` workflow can:
- authenticate to Azure via OIDC, and
- read/write state in an Azure Storage container.

- [ ] **Confirm the Azure subscription** where the tfstate storage account will live. → Dov / Willy.
- [ ] Create a dedicated resource group + storage account for tfstate (or reuse an existing one). Suggested names:
      ```bash
      az group create --name rg-dk-confluent-tfstate --location eastus
      az storage account create \
        --name dkconfluenttfstate \
        --resource-group rg-dk-confluent-tfstate \
        --location eastus \
        --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2
      az storage container create \
        --name tfstate \
        --account-name dkconfluenttfstate \
        --auth-mode login
      ```
- [ ] Plug the chosen values into the `TG_STATE_*` env vars (in `.env` locally, and as workflow env in GitHub):
      - `TG_STATE_RESOURCE_GROUP`
      - `TG_STATE_STORAGE_ACCOUNT`
      - `TG_STATE_CONTAINER`
      - `ARM_SUBSCRIPTION_ID`
      - `ARM_TENANT_ID`
- [ ] **Create an Entra app for GitHub Actions OIDC federation.** (See `poc-infra/scripts/bootstrap-gh-oidc.sh` for the Ayele-side reference; adapt the names.)
      ```bash
      APP_ID=$(az ad app create --display-name "dk-confluent-workload-gh-actions" --sign-in-audience AzureADMyOrg --query appId -o tsv)
      SP_OID=$(az ad sp create --id "$APP_ID" --query id -o tsv)

      # Federated credentials for main branch + PRs
      az ad app federated-credential create --id "$APP_ID" --parameters '{
        "name":"gh-main",
        "issuer":"https://token.actions.githubusercontent.com",
        "subject":"repo:<OWNER>/<REPO>:ref:refs/heads/main",
        "audiences":["api://AzureADTokenExchange"]}'
      az ad app federated-credential create --id "$APP_ID" --parameters '{
        "name":"gh-pr",
        "issuer":"https://token.actions.githubusercontent.com",
        "subject":"repo:<OWNER>/<REPO>:pull_request",
        "audiences":["api://AzureADTokenExchange"]}'

      # RBAC — Storage Blob Data Contributor on the state SA
      SA_ID=$(az storage account show --name dkconfluenttfstate --resource-group rg-dk-confluent-tfstate --query id -o tsv)
      az role assignment create --role "Storage Blob Data Contributor" \
        --assignee-object-id "$SP_OID" --assignee-principal-type ServicePrincipal \
        --scope "$SA_ID"
      ```
- [ ] Note the `APP_ID` from above — you'll paste it into `AZURE_CLIENT_ID` in GitHub secrets.

---

## 4. GitHub repo secrets

Set these on the DKP repo → Settings → Secrets and variables → Actions:

| Name | Value |
|---|---|
| `AZURE_CLIENT_ID`            | `APP_ID` from step 3 |
| `AZURE_TENANT_ID`            | DKP Entra tenant: `7bab0bc1-bb61-48d7-b2d4-79825c2ac6b8` |
| `AZURE_SUBSCRIPTION_ID`      | DKP tfstate subscription |
| `CONFLUENT_CLOUD_API_KEY`    | Cloud API key with `OrganizationAdmin` in DKP's Confluent org |
| `CONFLUENT_CLOUD_API_SECRET` | Matching secret |

Verify by running the workflow with `stack=dev, action=plan` from the Actions tab (see step 7).

---

## 5. Wire up the workloads JSON

- [ ] Entra admin runs the runbook (`docs/DK-Confluent-Entra-App-Runbook.docx`) or the PowerShell scripts (`powershell/scripts/New-WorkloadApps.ps1`) to create the 15 app registrations. Completed spreadsheet (`docs/app-registrations.xlsx`) comes back with Application (client) IDs filled in.
- [ ] Paste each `Application (client) ID` from spreadsheet column O into the matching workload key in:
      - `terraform/live/dev/workloads.json`
      - `terraform/live/uat/workloads.json`
      - `terraform/live/prd/workloads.json`
- [ ] Replace every other `REPLACE_WITH_…` placeholder in the three JSON files using the answers from step 2 (org ID, cluster IDs, prd topic list, etc.).
- [ ] `git grep REPLACE_WITH_` in the repo should return **zero** matches before you apply.

---

## 6. Confluent Cloud identity provider

- [ ] **If DKP already has a provider** (likely): note its `op-*` ID. Do **not** apply `terraform/live/_org/`. In each per-env `terragrunt.hcl`, replace the `dependency "provider"` block with a direct input:
      ```hcl
      inputs = {
        identity_provider_id = "op-<DKP_PROVIDER>"
        # ...
      }
      ```
- [ ] **If DKP doesn't have one:** leave the `_org` stack in place and apply it first.

---

## 7. Apply order

All via GitHub Actions (`terraform-workload.yml`, `workflow_dispatch`). For each run, pick `stack` and `action`.

- [ ] `plan` dev → review output, confirm it matches the workload/topic expectations, no placeholders remain.
- [ ] `apply` `_org` (only if DKP doesn't already have a provider).
- [ ] `apply` dev.
- [ ] Smoke-test a client connection from a DKP-side workload using the pool's `dk-confluent-dev-<workload>` identity pool + v2 token.
- [ ] `plan` + `apply` uat.
- [ ] `plan` + `apply` prd (once prd topic catalog is received from Rukai).

---

## 8. Validation after each apply

For each env stack, open the Confluent Console → Accounts & access → Workload identities → `DKP Entra ID` → Identity pools. Confirm:

- [ ] All 5 pools exist with the correct display name (`dk-confluent-<env>-<domain>-<workload>`).
- [ ] Filter on each pool matches `claims.tid == "7bab0bc1-…" && claims.aud == "<app-client-id>"`.
- [ ] Role bindings per pool match the topic access list in `workloads.json` (check in Console → Environment → Access → Role bindings, filter by the pool's `User:pool-*` principal).

For a live-token check: decode a real JWT at `https://jwt.ms` — `iss` must be `https://login.microsoftonline.com/7bab0bc1-…/v2.0`, `aud` must be the Application (client) ID GUID (no `api://` prefix).

---

## 9. Optional — enable the PowerShell scripts path

If DKP's Entra admin prefers PowerShell to the portal:

- [ ] `pwsh` 7.0+ installed
- [ ] `Install-Module Microsoft.Graph.Applications, Microsoft.Graph.Authentication -Scope CurrentUser`
- [ ] `Connect-MgGraph -TenantId 7bab0bc1-… -Scopes "Application.ReadWrite.All"`
- [ ] Copy each `powershell/config/workloads.<env>.json` template from `workloads.example.json`, fill in, and run `New-WorkloadApps.ps1 -ConfigPath <path>`.

---

## 10. Tear-down (reference)

Destroy order is the reverse of apply — destroys for the three env stacks are independent, then `_org`:

```bash
# via GH Actions: workflow_dispatch with action=destroy
prd → uat → dev → _org
```

Role bindings created by an identity pool are deleted automatically when the pool is destroyed; the pools are deleted when the env stack is destroyed; the provider is deleted last.

**Do not destroy `_org` if DKP's other workloads depend on the provider.**
