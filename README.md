# DK Workload Identity — Confluent Cloud × Microsoft Entra ID

Production-side code for federating DKP's Kafka workloads to Microsoft Entra ID
so clients authenticate with Entra-issued JWTs instead of static Kafka API keys.

## What's in this repo

```
├── CHECKLIST.md                  # ← start here when plumbing the code into DKP's env
├── terraform/                    # Confluent Cloud side (identity provider + pools + RBAC)
│   ├── modules/
│   │   ├── confluent-identity-provider/
│   │   └── confluent-workload-pools/
│   └── live/                     # per-stack Terragrunt configs (reads workloads.json)
│       ├── _org/                 # org-level identity provider (one per tenant)
│       ├── dev/                  # + workloads.json
│       ├── uat/                  # + workloads.json
│       └── prd/                  # + workloads.json
├── tools/                        # pinned CLI versions (Terraform, Terragrunt, Confluent, Python)
├── .github/workflows/            # GitHub Actions for plan/apply
├── docs/
│   ├── DK-Confluent-Entra-App-Runbook.docx   # manual Entra app registration procedure
│   └── app-registrations.xlsx                # one row per (env, domain, workload) — paired with the runbook
└── powershell/                   # optional — automated alternative to the docx runbook (Microsoft.Graph)
```

## How the pieces fit

1. **Azure / Entra side.** DKP's Entra admin creates 15 app registrations (5 workloads × 3 envs) using either:
   - `docs/DK-Confluent-Entra-App-Runbook.docx` paired with `docs/app-registrations.xlsx` (portal / manual), **or**
   - `powershell/scripts/New-WorkloadApps.ps1` (automated, requires Microsoft.Graph PowerShell module).
2. **Hand back the filled-in spreadsheet** to the team running Terraform.
3. **Update `terraform/live/<env>/workloads.json`** with the Application (client) IDs from the spreadsheet.
4. **Run the `terraform-workload` GitHub Actions workflow** per env (`_org` first, then `dev` → `uat` → `prd`).

The Confluent identity provider (`op-*`) is **organization-level** — one per Entra tenant. DKP
already has one wired up to the DKP Entra tenant, so the `_org` stack is optional for DKP's
deployment; supply the existing provider's ID as an override if skipping `_org`.

## Naming convention

```
dk-confluent-{env}-{domain}-{workload}
```

`{env}` ∈ {`dev`, `uat`, `prd`}. Example: `dk-confluent-dev-mergerarb-madam`.
Both Entra app display names and Confluent identity pool names follow this convention,
so pairs are recognizable side-by-side in both consoles.

## Next step

**Open `CHECKLIST.md`** — it walks you through every step of standing this up in DKP's
environment, and calls out the facts you need to collect from DKP (org ID, cluster IDs,
state-backend details, GitHub OIDC federated credential, etc.).

## Guidelines

Project-wide conventions (code style, secrets handling, git workflow) live in
`CLAUDE.md` at the repo root. Read it before contributing.
