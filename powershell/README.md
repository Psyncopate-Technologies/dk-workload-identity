# powershell/ — Entra ID app registrations

This is the **Azure / Entra side** of the workload-identity setup. PowerShell,
run by the tenant's Entra admin on their laptop (or in Azure Cloud Shell). It
creates:

- One **app registration** per workload, named `dk-confluent-{env}-{domain}-{workload}`
- An **Expose-an-API** entry so the app is a valid token resource (aud = `api://<client-id>`)
- Optional **federated credentials** (for Arc / GitHub OIDC / K8s workload identity)
- Optional **client secrets** (for Path 2 — legacy on-prem servers, or for local PoC testing)

Output of every script feeds the Terraform `workloads` map in
`../terraform/live/<env>/terragrunt.hcl`.

## Layout

```
powershell/
├── lib/
│   └── DkEntraApps.ps1             # shared helper functions (dot-sourced)
├── scripts/
│   ├── New-WorkloadApps.ps1        # create/update apps + scopes + federated creds (idempotent)
│   ├── Export-WorkloadApps.ps1     # dump live appIds as JSON (paste into terragrunt)
│   ├── New-ClientSecret.ps1        # generate a client secret for Path 2 / PoC
│   └── Remove-WorkloadApps.ps1     # delete apps declared in the config
└── config/
    ├── workloads.example.json      # committed template
    └── workloads.<env>.json        # your real config (gitignored)
```

## Prerequisites

1. **PowerShell 7+** (`pwsh`). On macOS: `brew install --cask powershell`.
2. **Microsoft.Graph** PowerShell module v2+:

   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```

3. Graph permissions: `Application.ReadWrite.All` (to create apps) or `Application.Read.All` (Export only).
   Your signed-in user must be either an **Application Administrator** or have delegated consent.

## Connecting

```powershell
Connect-MgGraph -TenantId 1b9dca15-4db4-4905-8725-d318d11c6875 `
                -Scopes "Application.ReadWrite.All"
```

This opens a browser login against Ayele's dev Entra tenant. The CLI session it
creates is picked up by every script below.

## Typical flow

```powershell
# 1. Copy the example config and fill it in.
cp powershell/config/workloads.example.json powershell/config/workloads.dev.json
# edit workloads.dev.json — set federatedCredentials[*].subject, etc.

# 2. Create the app registrations.
./powershell/scripts/New-WorkloadApps.ps1 -ConfigPath ./powershell/config/workloads.dev.json
# → prints appId per workload

# 3. Paste the appIds into terraform/live/dev/terragrunt.hcl under workloads[*].app_client_id.
#    Or dump them to JSON:
./powershell/scripts/Export-WorkloadApps.ps1 -ConfigPath ./powershell/config/workloads.dev.json

# 4. (Local PoC only) Create a client secret for one workload.
./powershell/scripts/New-ClientSecret.ps1 -ConfigPath ./powershell/config/workloads.dev.json `
                                           -WorkloadKey mergerarb-madam
# → secret is printed once; paste into your gitignored .env
```

## Config shape

See `config/workloads.example.json`. One JSON file per environment.

```json
{
  "environment": "dev",
  "namePrefix": "dk-confluent",
  "tenantId": "<entra-tenant-id>",
  "workloads": {
    "<domain>-<workload>": {
      "description": "...",
      "apiScopeName": "access_as_application",
      "federatedCredentials": [
        { "name": "...", "issuer": "...", "subject": "...", "audiences": ["api://AzureADTokenExchange"] }
      ]
    }
  }
}
```

`environment` + `namePrefix` + workload key combine to form the app display name
(`dk-confluent-dev-mergerarb-madam`), which must match the pool display name
the Terraform side produces — that's how you'll recognize the pair in the Console.

## Federated credentials — quick guide

| Scenario | Issuer | Subject |
|---|---|---|
| Azure UAMI | `https://login.microsoftonline.com/<tenant>/v2.0` | UAMI object (principal) ID |
| Azure Arc-enabled server | `https://sts.windows.net/<tenant>/` (Arc-issued) | Arc-generated subject per the server's resource ID |
| GitHub Actions OIDC | `https://token.actions.githubusercontent.com` | `repo:<org>/<repo>:environment:<env>` |
| Kubernetes (AKS workload identity) | AKS OIDC issuer URL | `system:serviceaccount:<ns>:<sa>` |

Azure-native workloads with a UAMI **do not need** a federated credential on
the app — the UAMI can call IMDS directly and receive a token with audience
`api://<app-client-id>`. Federation is only needed when the token issuer is
*not* Entra itself.

## Notes for DK's deployment

- DK already has their `DKP Entra ID` identity provider wired up in Confluent Cloud —
  they skip the Terraform `_org/` stack.
- DK's Entra admin runs these scripts once per environment, in their own tenant,
  to create app registrations. Only the admin's tenant ID and workloads change;
  the scripts themselves are tenant-agnostic.
