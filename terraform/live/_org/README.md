# terraform/live/_org/

Creates the org-level `confluent_identity_provider` — one per Entra tenant.

- `display_name`: `DK Entra ID` (edit in `terragrunt.hcl` if DKP prefers something else).
- Derives issuer + JWKS URIs from the tenant ID.

## When to apply this stack

Apply **once per Confluent Cloud organization** when an identity provider for
the DKP Entra tenant does not already exist.

## When to skip this stack

If DKP already has an identity provider wired to their Entra tenant, skip
`_org/` entirely and supply the existing provider's `op-*` ID to the per-env
stacks via one of:

1. Edit each `live/<env>/terragrunt.hcl` — replace the `dependency "provider"` block with:
   ```hcl
   inputs = {
     identity_provider_id = "<op-EXISTING>"
     ...
   }
   ```
2. Or set a Terragrunt input override via a higher-level `_env` shared config.

## Output

| Output | Use |
|---|---|
| `identity_provider_id` | `op-*` — consumed by the dependency block in `live/<env>/terragrunt.hcl` |
| `issuer`               | Resolved issuer URL — cross-check against decoded JWT `iss` claim |
