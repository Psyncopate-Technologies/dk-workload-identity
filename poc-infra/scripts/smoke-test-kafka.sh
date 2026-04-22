#!/usr/bin/env bash
# Runs /opt/smoke-test.py on the poc-infra test-client VM via `az vm run-command`.
# The VM (no public IP) sits in the nonprod compute subnet and has network access to
# the Private Endpoint for the Enterprise Kafka cluster.
#
# Reads config from env vars so nothing sensitive lands in argv / process list:
#   VM_RG, VM_NAME  — Azure VM location
#   BOOTSTRAP       — Kafka bootstrap (lkc-*.eastus.azure.private.confluent.cloud:9092)
#   CLUSTER_ID      — lkc-* (for SASL extension)
#   POOL_ID         — pool-* (for SASL extension)
#   TENANT_ID       — Entra tenant
#   CLIENT_ID       — app registration client ID
#   CLIENT_SECRET   — app client secret (Path-2 flow)
#   TOPIC           — optional; default mergerarb.madam.test

set -euo pipefail

: "${VM_RG:?VM_RG required}"
: "${VM_NAME:?VM_NAME required}"
: "${BOOTSTRAP:?BOOTSTRAP required}"
: "${CLUSTER_ID:?CLUSTER_ID required}"
: "${POOL_ID:?POOL_ID required}"
: "${TENANT_ID:?TENANT_ID required}"
: "${CLIENT_ID:?CLIENT_ID required}"
: "${CLIENT_SECRET:?CLIENT_SECRET required}"
TOPIC="${TOPIC:-mergerarb.madam.test}"

SCRIPT=$(cat <<REMOTE
export CLIENT_ID='${CLIENT_ID}'
export CLIENT_SECRET='${CLIENT_SECRET}'
export TENANT_ID='${TENANT_ID}'
export CLUSTER_ID='${CLUSTER_ID}'
export POOL_ID='${POOL_ID}'
export BOOTSTRAP='${BOOTSTRAP}'
export TOPIC='${TOPIC}'
python3 /opt/smoke-test.py
REMOTE
)

echo "Invoking smoke test on ${VM_NAME} (RG=${VM_RG})..."
az vm run-command invoke \
  --resource-group "${VM_RG}" \
  --name "${VM_NAME}" \
  --command-id RunShellScript \
  --scripts "${SCRIPT}" \
  --query "value[0].message" -o tsv
