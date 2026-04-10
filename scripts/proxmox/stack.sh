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
SCP_OPTS=(-i "${VM_SSH_PRIVATE_KEY_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P "${VM_SSH_PORT}")

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

pre_config_status="$(qm status "${VM_ID}" | awk '{print $2}')"
if [[ "${pre_config_status}" == "running" ]]; then
  log "VM ${VM_ID} is running; stopping it to avoid hotplug errors during qm set"
  qm shutdown "${VM_ID}" --timeout 60 || true

  for _ in $(seq 1 30); do
    current_status="$(qm status "${VM_ID}" | awk '{print $2}')"
    [[ "${current_status}" == "stopped" ]] && break
    sleep 2
  done

  if [[ "$(qm status "${VM_ID}" | awk '{print $2}')" != "stopped" ]]; then
    log "Graceful shutdown timed out; forcing stop"
    qm stop "${VM_ID}"
  fi
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

to_mb() {
  local size="$1"
  size="${size^^}"
  if [[ "${size}" =~ ^([0-9]+)([TGMK])$ ]]; then
    local value="${BASH_REMATCH[1]}"
    local unit="${BASH_REMATCH[2]}"
    case "${unit}" in
      T) echo $(( value * 1024 * 1024 )) ;;
      G) echo $(( value * 1024 )) ;;
      M) echo "${value}" ;;
      K) echo $(( value / 1024 )) ;;
    esac
  else
    fail "Unsupported disk size format: ${size}"
  fi
}

current_disk_raw="$(qm config "${VM_ID}" | awk -F'size=' '/^scsi0:/ {split($2,a,","); print a[1]; exit}')"
requested_disk_raw="${VM_DISK_SIZE^^}"

current_disk_mb="$(to_mb "${current_disk_raw}")"
requested_disk_mb="$(to_mb "${requested_disk_raw}")"

if (( requested_disk_mb > current_disk_mb )); then
  log "Resizing disk from ${current_disk_raw} to ${requested_disk_raw}"
  qm resize "${VM_ID}" scsi0 "${VM_DISK_SIZE}"
else
  log "Disk resize not needed (current: ${current_disk_raw:-unknown}, requested: ${requested_disk_raw})"
fi

vm_status="$(qm status "${VM_ID}" | awk '{print $2}')"
if [[ "${vm_status}" != "running" ]]; then
  log "Starting VM ${VM_ID}"
  qm start "${VM_ID}"
else
  log "Rebooting VM ${VM_ID} to apply updated cloud-init network settings"
  qm reboot "${VM_ID}"
fi

log "Waiting for SSH on ${VM_SSH_HOST}:${VM_SSH_PORT}"
for _ in $(seq 1 90); do
  vm_runtime_status="$(qm status "${VM_ID}" | awk '{print $2}')"
  if [[ "${vm_runtime_status}" == "stopped" ]]; then
    fail "VM ${VM_ID} stopped unexpectedly before SSH became reachable (possible kernel panic/template issue)"
  fi

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
REMOTE_APP_DIR="${REMOTE_APP_DIR:-/home/${VM_CIUSER}/homelab-core}"
LOCAL_SECRETS_FILE="${ROOT_DIR}/secrets/homelab-core.env"

[[ -f "${LOCAL_SECRETS_FILE}" ]] || fail "Missing secrets file: ${LOCAL_SECRETS_FILE}"

if [[ "${SKIP_DEPLOY:-0}" == "1" ]]; then
  log "SKIP_DEPLOY=1 set; provisioning finished without docker deployment"
  exit 0
fi

log "Waiting for SSH key authentication"

resolve_remote_user() {
  local candidate
  for candidate in "${VM_CIUSER}" "${TEMPLATE_CIUSER:-}" ubuntu debian; do
    [[ -n "${candidate}" ]] || continue
    if ssh "${SSH_OPTS[@]}" "${candidate}@${VM_SSH_HOST}" "true" >/dev/null 2>&1; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

REMOTE_USER=""
for _ in $(seq 1 120); do
  if REMOTE_USER="$(resolve_remote_user)"; then
    break
  fi
  sleep 2
done

[[ -n "${REMOTE_USER}" ]] || fail "SSH authentication failed. Cloud-init may still be applying keys or ciuser is wrong."
if [[ "${REMOTE_USER}" != "${VM_CIUSER}" ]]; then
  log "SSH login with ${VM_CIUSER} failed; using ${REMOTE_USER}"
fi

REMOTE_TARGET="${REMOTE_USER}@${VM_SSH_HOST}"

log "Copying Docker stack artifacts to VM"
ssh "${SSH_OPTS[@]}" "${REMOTE_TARGET}" "mkdir -p '${REMOTE_TMP_DIR}'"
scp "${SCP_OPTS[@]}" \
  "${ROOT_DIR}/docker/homelab-core/docker-compose.yml" \
  "${ROOT_DIR}/docker/homelab-core/.env.example" \
  "${ROOT_DIR}/scripts/docker/deploy_stack.sh" \
  "${ROOT_DIR}/scripts/docker/healthcheck.sh" \
  "${LOCAL_SECRETS_FILE}" \
  "${REMOTE_TARGET}:${REMOTE_TMP_DIR}/"

log "Deploying stack remotely"
ssh "${SSH_OPTS[@]}" "${REMOTE_TARGET}" "bash '${REMOTE_TMP_DIR}/deploy_stack.sh' '${REMOTE_TMP_DIR}' '${REMOTE_APP_DIR}'"

log "Done. VM ${VM_NAME} is provisioned and docker compose is up."
