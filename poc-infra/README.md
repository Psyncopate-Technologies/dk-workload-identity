# poc-infra — PoC-only Azure + Confluent Cloud infrastructure

**Do not ship this tree to DK.** DKP already has their production environment,
clusters, and PrivateLink wired up — this tree exists to mirror their layout in
Ayele's dev Confluent Cloud org + Azure tenant for validation.

Mirrors what DKP has:

- 1 Confluent Cloud environment (`DK-POC-STREAMING-MESH`)
- 2 Enterprise Kafka clusters: `dk-confluent-poc-nonprod-enterprise`, `dk-confluent-poc-prod-enterprise`
- 1 PrivateLink Attachment gateway (`DK-POC-PVTLINK-GATEWAY`) with 2 access points (nonprod + prod)
- 2 Azure VNets in `eastus` (one per tier), each with a private-endpoint subnet
- 1 Azure Private DNS zone covering both tiers

## Layout

```
poc-infra/
├── modules/
│   ├── azure-network/              # RG + 2 VNets + PE subnets
│   ├── confluent-platform/         # env + 2 Enterprise clusters + PL attachment
│   └── azure-private-endpoints/    # Private Endpoints + DNS zone + Confluent access-point connections
└── live/
    ├── root.hcl                    # providers (azurerm + confluent), local state
    ├── azure-network/              # apply first
    ├── confluent-platform/         # apply second
    └── azure-private-endpoints/    # apply last — depends on both
```

## Prerequisites

Environment variables (via `.env` at the repo root):

| Var | Source |
|---|---|
| `TF_VAR_confluent_cloud_api_key` / `TF_VAR_confluent_cloud_api_secret` | `/Users/ayeleadmassu/Documents/Confluent-PS/DKP/engagment-2/Day-2/credentials/` |
| `TF_VAR_azure_subscription_id` | Azure portal — pick the subscription to land the VNets in |
| `TF_VAR_azure_tenant_id` | `1b9dca15-4db4-4905-8725-d318d11c6875` |

Plus: `az login` in the current shell (Terraform's AzureRM provider picks up the CLI session).

## Apply order

```bash
set -a; source ../../.env; set +a

cd poc-infra/live/azure-network       && terragrunt apply
cd ../confluent-platform              && terragrunt apply
cd ../azure-private-endpoints         && terragrunt apply
```

## Known TODOs (need confirmation before apply)

- **Azure subscription** — pick which one the PoC lands in; update `.env`.
- **CIDR blocks** — current pick (`10.40.0.0/16`, `10.41.0.0/16`) is placeholder; confirm they don't collide with anything you peer to.
- **Confluent provider resources** — `confluent_private_link_attachment` and `confluent_private_link_attachment_connection` resource shapes may need tweaking against the installed provider version (2.10+). First `terragrunt plan` will surface argument mismatches.
- **Private DNS A records** — Confluent's automatic Azure Private DNS integration handles cluster-bootstrap records once the access-point connection is READY. If it doesn't, we'll need to add explicit `azurerm_private_dns_a_record` entries per cluster.

## CI

`.github/workflows/terraform-poc-infra.yml` (separate from the DK-shipped workflow).
