#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config/homelab.env"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_var() {
  local var_name="$1"
  [[ -n "${!var_name:-}" ]] || fail "Required variable is missing: ${var_name}"
}

if [[ ! -f "${CONFIG_FILE}" ]]; then
  fail "Configuration file not found: ${CONFIG_FILE}"
fi

# shellcheck disable=SC1090
source "${CONFIG_FILE}"

required_vars=(
  PVE_NODE_NAME
  PVE_TEMPLATE_ID
  PVE_STORAGE
  VM_ID
  VM_NAME
  VM_CORES
  VM_MEMORY_MB
  VM_DISK_SIZE
  VM_BRIDGE
  VM_IP_CIDR
  VM_GATEWAY
  VM_CIUSER
  VM_SSH_PUBLIC_KEY_FILE
)

for var_name in "${required_vars[@]}"; do
  require_var "${var_name}"
done

[[ -f "${VM_SSH_PUBLIC_KEY_FILE}" ]] || fail "SSH public key file not found: ${VM_SSH_PUBLIC_KEY_FILE}"

VM_IP="${VM_IP_CIDR%%/*}"
VM_SSH_HOST="${VM_SSH_HOST:-$VM_IP}"
VM_SSH_PORT="${VM_SSH_PORT:-22}"
VM_SSH_PRIVATE_KEY_FILE="${VM_SSH_PRIVATE_KEY_FILE:-${HOME}/.ssh/id_rsa}"
SSH_OPTS=(-i "${VM_SSH_PRIVATE_KEY_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "${VM_SSH_PORT}")

require_cmd qm
require_cmd ssh
require_cmd scp
require_cmd nc

if qm status "${VM_ID}" >/dev/null 2>&1; then
  log "VM ${VM_ID} (${VM_NAME}) already exists. Skipping clone."
else
  log "Cloning template ${PVE_TEMPLATE_ID} to VM ${VM_ID} (${VM_NAME})"
  qm clone "${PVE_TEMPLATE_ID}" "${VM_ID}" --name "${VM_NAME}" --target "${PVE_NODE_NAME}" --full 1 --storage "${PVE_STORAGE}"
fi

log "Applying VM configuration"
qm set "${VM_ID}" \
  --cores "${VM_CORES}" \
  --memory "${VM_MEMORY_MB}" \
  --net0 "virtio,bridge=${VM_BRIDGE}" \
  --ciuser "${VM_CIUSER}" \
  --sshkey "${VM_SSH_PUBLIC_KEY_FILE}" \
  --ipconfig0 "ip=${VM_IP_CIDR},gw=${VM_GATEWAY}" \
  --agent 1

current_disk_gb="$(qm config "${VM_ID}" | awk -F'size=' '/^scsi0:/ {gsub(/G.*/,"",$2); print $2; exit}')"
requested_disk_gb="${VM_DISK_SIZE%G}"

if [[ -n "${current_disk_gb}" ]] && (( requested_disk_gb > current_disk_gb )); then
  log "Resizing disk from ${current_disk_gb}G to ${requested_disk_gb}G"
  qm resize "${VM_ID}" scsi0 "${VM_DISK_SIZE}"
else
  log "Disk resize not needed (current: ${current_disk_gb:-unknown}G, requested: ${requested_disk_gb}G)"
fi

vm_status="$(qm status "${VM_ID}" | awk '{print $2}')"
if [[ "${vm_status}" != "running" ]]; then
  log "Starting VM ${VM_ID}"
  qm start "${VM_ID}"
else
  log "VM ${VM_ID} is already running"
fi

log "Waiting for SSH on ${VM_SSH_HOST}:${VM_SSH_PORT}"
for _ in $(seq 1 90); do
  if nc -z "${VM_SSH_HOST}" "${VM_SSH_PORT}" >/dev/null 2>&1; then
    log "SSH port is reachable"
    break
  fi
  sleep 2
done

if ! nc -z "${VM_SSH_HOST}" "${VM_SSH_PORT}" >/dev/null 2>&1; then
  fail "SSH is not reachable on ${VM_SSH_HOST}:${VM_SSH_PORT}"
fi

REMOTE_TMP_DIR="/tmp/homelab-stack"
REMOTE_APP_DIR="${REMOTE_APP_DIR:-/opt/homelab-core}"
REMOTE_TARGET="${VM_CIUSER}@${VM_SSH_HOST}"
LOCAL_SECRETS_FILE="${ROOT_DIR}/secrets/homelab-core.env"

[[ -f "${LOCAL_SECRETS_FILE}" ]] || fail "Missing secrets file: ${LOCAL_SECRETS_FILE}"

log "Copying Docker stack artifacts to VM"
ssh "${SSH_OPTS[@]}" "${REMOTE_TARGET}" "mkdir -p '${REMOTE_TMP_DIR}'"
scp "${SSH_OPTS[@]}" \
  "${ROOT_DIR}/docker/homelab-core/docker-compose.yml" \
  "${ROOT_DIR}/docker/homelab-core/.env.example" \
  "${ROOT_DIR}/scripts/docker/deploy_stack.sh" \
  "${ROOT_DIR}/scripts/docker/healthcheck.sh" \
  "${LOCAL_SECRETS_FILE}" \
  "${REMOTE_TARGET}:${REMOTE_TMP_DIR}/"

log "Deploying stack remotely"
ssh "${SSH_OPTS[@]}" "${REMOTE_TARGET}" "bash '${REMOTE_TMP_DIR}/deploy_stack.sh' '${REMOTE_TMP_DIR}' '${REMOTE_APP_DIR}'"

log "Done. VM ${VM_NAME} is provisioned and docker compose is up."
