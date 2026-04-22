# .github/workflows/

| File | Workflow name | What it does |
|---|---|---|
| `terraform-workload.yml` | `terraform-workload` | Applies `terraform/live/<stack>` for the selected stack (`_org` / `dev` / `uat` / `prd`) and action (`plan` / `apply` / `destroy`). PRs auto-`plan`. |

See `../README.md` for secret + RBAC prerequisites.

## Local CLI equivalent

```bash
set -a; source ../../.env; set +a
source tools/env.sh
cd terraform/live/<stack>
terragrunt init && terragrunt plan
```
