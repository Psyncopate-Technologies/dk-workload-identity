# terraform/live/uat/

DKP's **uat** logical env. Same 5 workloads as `dev/` but scoped to `uat.*` /
`uat2.*` (plus `cdc.uat.position.*` for the reader) topic prefixes, landing on
the **same nonprod cluster** (`lkc-1o1jkv`). Identity pools are separated by
name (`dk-confluent-uat-...`) so there's no collision with dev.

## Configuration

Edit `workloads.json` next to this README. Fill in:

- `confluent_organization_id` — request from DKP.
- `workloads.<key>.app_client_id` — from the spreadsheet after the Entra admin creates each app (one row per env × workload).

## Apply

```bash
cd terraform/live/uat && terragrunt apply
```

Or via GitHub Actions: run `terraform-workload.yml` with `stack=uat`.
