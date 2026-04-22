# terraform/live/prd/

DKP's **prd** (production) logical env. Same 5 workloads as `dev/` and `uat/`
but targeting the **prod cluster** (`lkc-wxdwk9`).

**Status: topic placeholders.** Rukai has not yet provided the prd topic list.
`workloads.json` currently has `REPLACE_WITH_PRD_*` placeholders — request the
final prd topic catalog from DKP (see CHECKLIST.md) before applying.

## Configuration

Edit `workloads.json` and fill in:

- `confluent_organization_id` — request from DKP.
- `workloads.<key>.app_client_id` — from spreadsheet after Entra admin creates each app.
- All topic/group prefixes and names — request the final list from Rukai.

## Apply

```bash
cd terraform/live/prd && terragrunt apply
```

Or via GitHub Actions: run `terraform-workload.yml` with `stack=prd`.
