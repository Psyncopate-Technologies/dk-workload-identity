# terraform/live/dev/

DKP's **dev** logical env. Five workloads, all landing on the DKP nonprod
Enterprise Kafka cluster (`lkc-1o1jkv`). Dev logical env covers topic prefixes
`dev.*` and `dev2.*` per Rukai's topic allocation.

Workloads created:

| Key                   | Role                          | Access summary |
|---|---|---|
| `mergerarb-madam`     | Merger-Arb MADAM              | Write + Read on 8 **exact** topics `dev.deal.calc.mergerarb.*` / `dev.deal.mergerarb.compact.*` (JSON/AVRO, v1 + v2) |
| `position-writer`     | Position Service — writer     | Write on dev/dev2 prefix topics (transaction, allocation, sod.position, position, referencedata) |
| `position-reader`     | Position Service — reader     | Read on dev/dev2 prefix topics (deal, security, manager, fund, referencedata) |
| `tft-writer`          | TFT Service — writer          | Write on dev/dev2 prefix topics (deal, security, manager, fund) |
| `ibconnect-connector` | IB Connect connector          | Write on dev ibconnect.streams / ibconnect.rawstreams |

## Configuration

All workload details live in **`workloads.json`** alongside this README.
Edit that file (not `terragrunt.hcl`) to add/remove workloads or change topic
assignments.

Fields to fill in before first apply:

- `confluent_organization_id` — request from DKP Kafka admin (Rukai).
- `workloads.<key>.app_client_id` — fill in from the spreadsheet column O after the Entra admin creates each app.

The placeholders in `workloads.json` (`REPLACE_WITH_*`) fail loudly at plan time
if left in — that's intentional.

## Apply

```bash
cd terraform/live/dev
set -a; source ../../../.env; set +a
terragrunt apply
```

Or via GitHub Actions: run `terraform-workload.yml` with `stack=dev, action=apply`.
