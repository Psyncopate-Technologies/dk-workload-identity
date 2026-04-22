# confluent-identity-provider

Creates a single `confluent_identity_provider` resource — the org-level OIDC
trust anchor between Confluent Cloud and an Entra tenant. One provider per
tenant; all environments' identity pools reference it.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `display_name`      | string | — (required) | Shown in the Confluent Console (e.g. `DKP Entra ID`) |
| `description`       | string | `"Microsoft Entra ID OIDC identity provider."` | |
| `entra_tenant_id`   | string | — (required) | Entra tenant ID; also used to derive issuer + JWKS URIs when those aren't explicit. |
| `entra_issuer`      | string | `null` → `https://login.microsoftonline.com/<tenant>/v2.0` | Override only if DKP uses a non-default issuer. |
| `entra_jwks_uri`    | string | `null` → `https://login.microsoftonline.com/<tenant>/discovery/v2.0/keys` | Override only if DKP uses a non-default JWKS URL. |

## Outputs

| Name | Description |
|---|---|
| `identity_provider_id` | `op-*` — consumed by `confluent-workload-pools` as the pool's identity_provider |
| `display_name`         | Echoed back for cross-check |
| `issuer`               | Resolved issuer URL |

## DKP note

DKP already has an identity provider wired up to their Entra tenant. In DKP's
deployment the `_org/` stack that uses this module can be **skipped** — supply
the existing provider's `op-*` ID as an override to the per-env stacks.
