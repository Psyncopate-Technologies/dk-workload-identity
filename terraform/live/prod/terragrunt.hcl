include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/confluent-oidc"
}

inputs = {
  environment_name          = "prod"
  confluent_organization_id = "REPLACE_WITH_PROD_ORG_ID_IF_DIFFERENT"
  confluent_environment_id  = "REPLACE_WITH_PROD_CONFLUENT_ENV_ID"
  kafka_cluster_id          = "REPLACE_WITH_PROD_KAFKA_CLUSTER_ID"

  # Microsoft Entra ID — prod tenant
  entra_tenant_id = "REPLACE_WITH_PROD_TENANT_ID"
  entra_issuer    = "https://login.microsoftonline.com/REPLACE_WITH_PROD_TENANT_ID/v2.0"
  entra_jwks_uri  = "https://login.microsoftonline.com/REPLACE_WITH_PROD_TENANT_ID/discovery/v2.0/keys"

  producer_app_client_id = "REPLACE_WITH_PROD_PRODUCER_APP_CLIENT_ID"
  consumer_app_client_id = "REPLACE_WITH_PROD_CONSUMER_APP_CLIENT_ID"

  topic_prefix          = "dkp"
  consumer_group_prefix = "dkp"
}
