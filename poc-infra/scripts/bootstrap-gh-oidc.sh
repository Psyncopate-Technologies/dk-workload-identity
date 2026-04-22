#!/usr/bin/env bash
# One-time bootstrap for GitHub Actions → Azure OIDC auth used by the CI workflows.
#
# What it creates:
#   1. Entra app registration + service principal
#   2. Federated credentials for main-branch pushes + pull requests
#   3. RBAC: Storage Blob Data Contributor on the tfstate SA, Contributor on the PoC subscription
#
# Idempotency: re-running will fail on the app creation step if the app already exists.
# For re-runs, look up the existing app and skip to the pieces that need changing.
#
# Prereq: az login as an Owner of the target subscription + an Entra account that can create apps.

set -euo pipefail

APP_NAME="${APP_NAME:-dk-confluent-poc-gh-actions}"
GH_OWNER="${GH_OWNER:-Psyncopate-Technologies}"
GH_REPO="${GH_REPO:-dk-workload-identity}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-e2fc4b68-6dd0-4c89-99c6-d6b16f9a0eba}"
STATE_SA_NAME="${STATE_SA_NAME:-dkconfluentpoctfstate}"
STATE_SA_RG="${STATE_SA_RG:-rg-dk-confluent-poc-tfstate}"

echo "Creating Entra app '$APP_NAME'..."
APP_ID=$(az ad app create --display-name "$APP_NAME" --sign-in-audience AzureADMyOrg --query appId -o tsv)
SP_OID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
echo "  APP_ID=$APP_ID"
echo "  SP_OID=$SP_OID"

echo "Adding federated credentials..."
for spec in \
  'gh-main|repo:'"$GH_OWNER"'/'"$GH_REPO"':ref:refs/heads/main|pushes to main' \
  'gh-pull-request|repo:'"$GH_OWNER"'/'"$GH_REPO"':pull_request|pull requests'
do
  IFS='|' read -r name subject description <<< "$spec"
  az ad app federated-credential create --id "$APP_ID" --parameters "$(cat <<JSON
{
  "name": "$name",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "$subject",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions — $description"
}
JSON
)" --query name -o tsv
done

echo "Granting RBAC (sleeping 10s for SP propagation)..."
sleep 10
SA_ID=$(az storage account show --name "$STATE_SA_NAME" --resource-group "$STATE_SA_RG" --query id -o tsv)
az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id "$SP_OID" --assignee-principal-type ServicePrincipal --scope "$SA_ID" --query id -o tsv
az role assignment create --role "Contributor" --assignee-object-id "$SP_OID" --assignee-principal-type ServicePrincipal --scope "/subscriptions/$SUBSCRIPTION_ID" --query id -o tsv

cat <<EOF

=== Done. Add these GitHub repo secrets (Settings → Secrets and variables → Actions) ===

  AZURE_CLIENT_ID          = $APP_ID
  AZURE_TENANT_ID          = <your tenant id>
  AZURE_SUBSCRIPTION_ID    = $SUBSCRIPTION_ID
  CONFLUENT_CLOUD_API_KEY  = <Org API key from /path/to/api-keys.env>
  CONFLUENT_CLOUD_API_SECRET = <matching secret>

EOF
