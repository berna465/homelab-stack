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

destroy_vm() {
  local vmid="$1"
  if ! qm status "${vmid}" >/dev/null 2>&1; then
    log "VMID ${vmid} not found. Skipping."
    return 0
  fi

  local status
  status="$(qm status "${vmid}" | awk '{print $2}')"
  if [[ "${status}" == "running" ]]; then
    log "Stopping VMID ${vmid}"
    qm shutdown "${vmid}" --timeout 30 || true
    sleep 2
    status="$(qm status "${vmid}" | awk '{print $2}')"
    if [[ "${status}" == "running" ]]; then
      qm stop "${vmid}"
    fi
  fi

  log "Destroying VMID ${vmid}"
  qm destroy "${vmid}" --purge
}

[[ -f "${CONFIG_FILE}" ]] || fail "Configuration file not found: ${CONFIG_FILE}"
# shellcheck disable=SC1090
source "${CONFIG_FILE}"

require_cmd qm

TARGET="${1:-vm}"
case "${TARGET}" in
  vm)
    destroy_vm "${VM_ID}"
    ;;
  template)
    destroy_vm "${TEMPLATE_ID:-${PVE_TEMPLATE_ID:-902}}"
    ;;
  all)
    destroy_vm "${VM_ID}"
    destroy_vm "${TEMPLATE_ID:-${PVE_TEMPLATE_ID:-902}}"
    ;;
  *)
    fail "Usage: bash infra/proxmox/scripts/destroy_homelab.sh [vm|template|all]"
    ;;
esac

log "Destroy completed (${TARGET})"
