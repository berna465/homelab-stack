#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-home}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ENV_FILE="$BASE_DIR/config/environments/${ENV_NAME}.env"
SECRETS_FILE="$BASE_DIR/config/secrets/${ENV_NAME}.secrets.env"

source "$ENV_FILE"
[ -f "$SECRETS_FILE" ] && source "$SECRETS_FILE"

ensure_vm() {
  local VMID="$1"
  local NAME="$2"
  local CORES="$3"
  local MEMORY="$4"

  if qm status "$VMID" &>/dev/null; then
    echo "[INFO] VM $VMID esiste — aggiorno config"
    qm set "$VMID" --name "$NAME" --cores "$CORES" --memory "$MEMORY"
  else
    echo "[INFO] Creo VM $VMID ($NAME) dal template $TEMPLATE_VMID"
    qm clone "$TEMPLATE_VMID" "$VMID" --name "$NAME" --full --target "$TEMPLATE_STORAGE"
    qm set "$VMID" --cores "$CORES" --memory "$MEMORY"
  fi
}

echo "=== CONFIGURO infra-core ==="

ensure_vm "$INFRA_CORE_VMID" "$INFRA_CORE_NAME" "$INFRA_CORE_CORES" "$INFRA_CORE_MEMORY"

qm set "$INFRA_CORE_VMID" --net0 "virtio,bridge=${INFRA_CORE_NET0_BRIDGE}"
qm set "$INFRA_CORE_VMID" --net1 "virtio,bridge=${INFRA_CORE_NET1_BRIDGE}"

qm set "$INFRA_CORE_VMID" \
  --ipconfig0 "ip=${INFRA_CORE_NET0_IP},gw=${INFRA_CORE_NET0_GW}"
qm set "$INFRA_CORE_VMID" \
  --ipconfig1 "ip=${INFRA_CORE_NET1_IP}"

qm set "$INFRA_CORE_VMID" --nameserver "$DNS_SERVER" --searchdomain "$DNS_SEARCH"

qm start "$INFRA_CORE_VMID" || true

echo "=== CONFIGURO apps-core ==="

ensure_vm "$APPS_CORE_VMID" "$APPS_CORE_NAME" "$APPS_CORE_CORES" "$APPS_CORE_MEMORY"

qm set "$APPS_CORE_VMID" --net0 "virtio,bridge=${APPS_CORE_NET0_BRIDGE}"
qm set "$APPS_CORE_VMID" \
  --ipconfig0 "ip=${APPS_CORE_NET0_IP},gw=${APPS_CORE_NET0_GW}"

qm set "$APPS_CORE_VMID" --nameserver "$DNS_SERVER" --searchdomain "$DNS_SEARCH"

qm start "$APPS_CORE_VMID" || true

echo "=== DEPLOY COMPLETATO ==="
