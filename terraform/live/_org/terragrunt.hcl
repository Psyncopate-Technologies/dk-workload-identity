# Org-level Confluent Cloud identity provider — one per Entra tenant, shared across all envs.
#
# NOTE: DKP already has their own identity_provider wired up in their Confluent org.
# This stack is for Ayele's PoC dev org only. It still ships to DK as reference code,
# but DK will skip applying _org and instead pass their existing provider ID as a
# Terragrunt input override on the per-env stacks.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/confluent-identity-provider"
}

inputs = {
  display_name    = "DK Entra ID - TF Managed"
  description     = "Microsoft Entra ID OIDC provider — managed by terraform/live/_org. Singleton at the Confluent organization level."
  entra_tenant_id = "7bab0bc1-bb61-48d7-b2d4-79825c2ac6b8"
}
