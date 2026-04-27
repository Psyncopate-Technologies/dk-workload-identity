# docs/

Hand-off artifacts for DKP's Entra administrator.

| File | Purpose |
|---|---|
| `DK-Confluent-Entra-App-Runbook.docx`       | Manual Azure portal steps to create one app registration per (env, domain, workload). |
| `app-registrations.xlsx`                    | One row per app — every field the runbook asks for, plus two highlighted cells where the admin records the Application (client) ID and Object ID after creation. |
| `Workload-Identity-Auth-Patterns.docx`      | Two reference .NET projects for DKP application developers — Pattern A (client ID + client secret) and Pattern B (Function App + Managed Identity, passwordless). Side-by-side comparison, full source listings, and the v1/v2-token pitfall called out. |
| `generate_entra_app_runbook.py`             | Regenerates the runbook docx. Run after any structural change. |
| `generate_app_registrations_spreadsheet.py` | Regenerates the xlsx. Run when the workload list changes. |
| `generate_auth_patterns_doc.py`             | Regenerates the auth-patterns docx. Run when example code or pattern guidance changes. |

## Design

The runbook and spreadsheet are built to be used side-by-side. Every field the
admin enters in the Azure portal is sourced from a specific column in the
spreadsheet (columns referenced by letter in the runbook). The two highlighted
columns (O = Application (client) ID, P = Object ID) are filled in by the
admin after each app is created; everything else is constant per row.

## Regenerating

```bash
source tools/env.sh
python3 -m pip install --break-system-packages python-docx openpyxl
python3 docs/generate_entra_app_runbook.py
python3 docs/generate_app_registrations_spreadsheet.py
python3 docs/generate_auth_patterns_doc.py
```

## Who's in scope

15 app registrations total: 5 workloads × 3 envs (dev / uat / prd). See
`app-registrations.xlsx` for the full list.
