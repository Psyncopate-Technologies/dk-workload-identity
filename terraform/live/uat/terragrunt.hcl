include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/confluent-oidc"
}

inputs = {
  environment_name          = "uat"
  confluent_organization_id = "0369af3f-d68c-44de-97cb-52a50017dc59"
  confluent_environment_id  = "REPLACE_WITH_UAT_CONFLUENT_ENV_ID"
  kafka_cluster_id          = "REPLACE_WITH_UAT_KAFKA_CLUSTER_ID"

  # Microsoft Entra ID — uat tenant
  entra_tenant_id = "REPLACE_WITH_UAT_TENANT_ID"
  entra_issuer    = "https://login.microsoftonline.com/REPLACE_WITH_UAT_TENANT_ID/v2.0"
  entra_jwks_uri  = "https://login.microsoftonline.com/REPLACE_WITH_UAT_TENANT_ID/discovery/v2.0/keys"

  producer_app_client_id = "REPLACE_WITH_UAT_PRODUCER_APP_CLIENT_ID"
  consumer_app_client_id = "REPLACE_WITH_UAT_CONSUMER_APP_CLIENT_ID"

  topic_prefix          = "dkp"
  consumer_group_prefix = "dkp"
}
