# Architecture — What this Terraform code does

A reference for future-you (or whoever inherits this). Describes the module's scope, the 6 resources it creates, the end-to-end request flow, and the two identity paths the design supports.

---

## Scope

This module (`terraform/modules/confluent-oidc`) touches **only Confluent Cloud**. It does not touch Azure / Microsoft Entra at all — Entra app registrations, client secrets, and federated credentials are managed manually outside this code.

---

## The 6 resources per environment

### 1. `confluent_identity_provider.entra`

File: [modules/confluent-oidc/main.tf](modules/confluent-oidc/main.tf), line 8.

Registers Microsoft Entra ID as an OIDC trust anchor in Confluent Cloud. Tells Confluent:

- **Issuer** URL of tokens to accept: `https://login.microsoftonline.com/<tenant-id>/v2.0`
- **JWKS URI** to fetch Entra's public signing keys: `https://login.microsoftonline.com/<tenant-id>/discovery/v2.0/keys`

This is the "I trust tokens signed by this Entra tenant" declaration. Everything downstream chains off it.

### 2. `confluent_identity_pool.producer` / 3. `confluent_identity_pool.consumer`

Files: [modules/confluent-oidc/main.tf](modules/confluent-oidc/main.tf), lines 15 and 26.

The "who is this caller?" rules. Each pool has:

- `identity_claim = "claims.sub"` — the `sub` claim of the incoming token becomes the principal identity inside Confluent.
- A **filter expression** tokens must satisfy to be accepted into the pool:
  - Producer: `claims.tid == "<tenant-id>" && claims.aud == "api://<producer-app-client-id>"`
  - Consumer: `claims.tid == "<tenant-id>" && claims.aud == "api://<consumer-app-client-id>"`

Pools are segregated by the **audience** of the incoming token — different Entra app registrations yield different pools. The tenant ID check stops tokens from any other Entra tenant being accepted.

Once a token matches a pool, the pool becomes the principal (a dynamic service account like `User:pool-6Jqzr`).

### 4. `confluent_role_binding.producer_write`

File: [modules/confluent-oidc/main.tf](modules/confluent-oidc/main.tf), line 37.

Grants `DeveloperWrite` on topics `dkp*` to the **producer pool** principal. In practice lets producer-pool callers write to `dkp_test`.

### 5. `confluent_role_binding.consumer_read_topic`

File: [modules/confluent-oidc/main.tf](modules/confluent-oidc/main.tf), line 43.

Grants `DeveloperRead` on topics `dkp*` to the **consumer pool** principal. Lets consumer-pool callers read `dkp_test`.

### 6. `confluent_role_binding.consumer_read_group`

File: [modules/confluent-oidc/main.tf](modules/confluent-oidc/main.tf), line 49.

Grants `DeveloperRead` on consumer groups `dkp*` to the **consumer pool** principal. Kafka consume operations need read access to both the topic and the consumer group — this is the group half.

---

## The CRN glue

File: [modules/confluent-oidc/main.tf](modules/confluent-oidc/main.tf), line 5.

All three role bindings scope to:

```
crn://confluent.cloud/organization=<org-id>/environment=<env-id>/cloud-cluster=<cluster-id>/kafka=<cluster-id>/topic=dkp*
```

(or `group=dkp*` for binding 6). This hard-pins the grants to **one specific Kafka cluster in one specific environment** — grants can't leak to other clusters.

---

## What this Terraform does NOT do

- **Does not create the Kafka cluster or environment.** Both `env-xxx` and `lkc-xxx` are pre-existing inputs.
- **Does not create the topic `dkp_test`.** Only role bindings on the `dkp` prefix. Whoever creates the topic does it separately (Console / CLI / a different Terraform stack).
- **Does not touch Entra.** No app registrations, no client secrets, no federated credentials. The token-issuing side is entirely manual.
- **Does not care how callers get their tokens.** Client secrets, User-Assigned Managed Identities, federated credentials — all produce Entra JWTs that hit the same pool filter. That's why the two identity paths below need **zero Terraform changes** — the difference is upstream in how the token is minted, not downstream in how Confluent accepts it.

---

## End-to-end request flow

```
[Java / Function / on-prem app]
        │
        │ 1. Gets an Entra JWT (via Path 1 or Path 2 — see below)
        │    Token has: aud = api://<producer-client-id>, tid = <tenant>, sub = <identity>
        ▼
[Kafka client sends SASL/OAUTHBEARER with that JWT]
        │
        ▼
[Confluent validates signature using JWKS from identity_provider.entra]
        │
        ▼
[Confluent matches token against identity_pool filters]
        │
        │ aud = api://<producer-client-id> → producer-dev pool
        │ aud = api://<consumer-client-id> → consumer-dev pool
        ▼
[Principal becomes "User:pool-xxxxxx"]
        │
        ▼
[RBAC role bindings evaluated against the action]
        │
        │ Producer writes to topic dkp_test  → DeveloperWrite on dkp* → ALLOWED
        │ Consumer reads topic dkp_test      → DeveloperRead  on dkp* → ALLOWED
        │ Consumer joins group dkp-java-1    → DeveloperRead  on dkp* → ALLOWED
        ▼
[Kafka op succeeds]
```

---

## Two identity paths (both plug into this same Confluent setup)

### Path 1 — Federated / keyless identity

For Azure-native workloads (Azure Functions, App Service, VMs, AKS) and Azure Arc-enabled on-prem servers. Fully keyless — no secrets to store or rotate.

- **Azure-native workloads:** assign a User-Assigned Managed Identity (UAMI) to the workload. The workload calls IMDS / `DefaultAzureCredential` and gets an Entra token for `api://<producer-app-client-id>` directly. No federation needed — Azure mints the token.
- **Arc-enabled on-prem servers:** add a **federated credential** on the Entra app registration that trusts the Arc-issued assertion. The server uses the Arc-IMDS assertion to exchange for an Entra token via the `jwt-bearer` client assertion flow (`grant_type=client_credentials` + `client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer`).
- **Confluent side:** no change. Pool filter still matches on `tid` + `aud`. `sub` becomes the UAMI object ID (or the federated subject). Optionally tighten with `&& claims.oid == "<UAMI-object-id>"` if you want to lock a pool to one identity.
- **Pros:** zero secrets. Azure handles lifecycle.
- **Cons:** each Arc server needs a federated-credential entry (or a shared one with a careful subject design). Requires Arc enrollment.

### Path 2 — Client ID + client secret (OAuth client credentials grant)

For legacy on-prem servers that cannot run Azure Arc. Client secret stored in DKP's existing on-prem vault.

- On-prem app at boot: reads `client_id` (non-secret) and `client_secret` (from vault), calls Entra `/oauth2/v2.0/token` with `grant_type=client_credentials` + `scope=api://<client-id>/.default`, caches the returned token until `expires_in` expiry.
- Token goes to Kafka via SASL/OAUTHBEARER — same pool, same RBAC as Path 1.
- **Confluent side:** no change.
- **Pros:** no Azure dependency on the host.
- **Cons:** secrets must be rotated, audited, revoked if leaked. Vault becomes a startup dependency.

### Tightening a pool filter per path (optional)

| Goal | Add to pool filter |
|---|---|
| Only a specific Azure UAMI can use the pool | `&& claims.oid == "<UAMI-object-id>"` |
| Only the secret-based app can use the pool | `&& claims.appid == "<producer-client-id>"` |
| Exclude federated assertions (app-only tokens) | `&& claims.idtyp == "app"` |

If you need to separate traffic by path (UAMI vs. secret), that's when you add a second pool with a stricter filter. Not needed day one.

---

## Rollout order

1. Keep Path 2 running — dev already has it. It's the fallback while Path 1 is being built.
2. Stand up one non-prod Azure Function on Path 1 end-to-end. Confirm it produces with zero secrets.
3. Enroll one Arc server, add its federated credential, confirm it works.
4. Migrate servers Path 2 → Path 1 as Arc rollout progresses.
5. Path 2 sticks around for servers that can't run Arc.
