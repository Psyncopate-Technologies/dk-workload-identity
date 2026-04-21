include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/confluent-oidc"
}

inputs = {
  environment_name          = "dev"
  confluent_organization_id = "0369af3f-d68c-44de-97cb-52a50017dc59"
  confluent_environment_id  = "env-1y1176"
  kafka_cluster_id          = "lkc-x9qrwg"

  # Microsoft Entra ID — dev tenant
  entra_tenant_id = "1b9dca15-4db4-4905-8725-d318d11c6875"
  entra_issuer    = "https://login.microsoftonline.com/1b9dca15-4db4-4905-8725-d318d11c6875/v2.0"
  entra_jwks_uri  = "https://login.microsoftonline.com/1b9dca15-4db4-4905-8725-d318d11c6875/discovery/v2.0/keys"

  # App registration (client) IDs — one per workload, used to build api://<id> audience
  producer_app_client_id = "9dfb2b95-628d-4662-a8cd-88965d278cd9"
  consumer_app_client_id = "87b4c741-6871-4e82-a4a4-bf29ac592246"

  topic_prefix          = "dkp"
  consumer_group_prefix = "dkp"
}
