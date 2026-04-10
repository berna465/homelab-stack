#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config/homelab.env"
BUILD_TEMPLATE_SCRIPT="${REPO_ROOT}/scripts/proxmox/build_template.sh"
PROVISION_SCRIPT="${REPO_ROOT}/scripts/provision-vms.sh"
STACK_SCRIPT="${REPO_ROOT}/scripts/proxmox/stack.sh"
DESTROY_SCRIPT="${REPO_ROOT}/scripts/proxmox/destroy_homelab.sh"
BOOTSTRAP_SCRIPT="${REPO_ROOT}/scripts/bootstrap-node.sh"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<USAGE
Usage: bash scripts/run-homelab.sh [all|template|provision|bootstrap|stack|destroy [vm|template|all]]

Commands:
  all        Build template -> provision VM -> bootstrap node (default)
  template   Build/refresh template only
  provision  Provision VM only (no docker deploy)
  bootstrap  Bootstrap node only (run scripts/bootstrap-node.sh remotely)
  stack      Legacy stack flow (provision + deploy in one script)
  destroy    Destroy resources (default target: vm)
USAGE
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

resolve_remote_user() {
  local host="$1"
  local key="$2"
  local port="$3"
  local candidate
  local opts=(-i "${key}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "${port}")
  for candidate in "${VM_CIUSER}" "${TEMPLATE_CIUSER:-}" ubuntu debian; do
    [[ -n "${candidate}" ]] || continue
    if ssh "${opts[@]}" "${candidate}@${host}" "true" >/dev/null 2>&1; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

run_remote_bootstrap() {
  local host="${VM_SSH_HOST:-${VM_IP_CIDR%%/*}}"
  local port="${VM_SSH_PORT:-22}"
  local key="${VM_SSH_PRIVATE_KEY_FILE:-${HOME}/.ssh/id_rsa}"
  local user=""

  [[ -f "${key}" ]] || fail "SSH private key not found: ${key}"

  for _ in $(seq 1 45); do
    if user="$(resolve_remote_user "${host}" "${key}" "${port}")"; then
      break
    fi
    sleep 2
  done

  [[ -n "${user}" ]] || fail "Unable to authenticate on ${host} for bootstrap"

  local target="${user}@${host}"
  local ssh_opts=(-i "${key}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "${port}")

  log "Copying bootstrap-node.sh to ${target}"
  scp "${ssh_opts[@]}" "${BOOTSTRAP_SCRIPT}" "${target}:/tmp/bootstrap-node.sh"

  log "Running bootstrap-node.sh remotely"
  ssh "${ssh_opts[@]}" "${target}" "chmod +x /tmp/bootstrap-node.sh && (sudo -n bash /tmp/bootstrap-node.sh homelab-core || bash /tmp/bootstrap-node.sh homelab-core)"
}

COMMAND="${1:-all}"
DESTROY_TARGET="${2:-vm}"

[[ -f "${CONFIG_FILE}" ]] || fail "Configuration file not found: ${CONFIG_FILE}"
# shellcheck disable=SC1090
source "${CONFIG_FILE}"

[[ -x "${BUILD_TEMPLATE_SCRIPT}" ]] || fail "Template builder not executable: ${BUILD_TEMPLATE_SCRIPT}"
[[ -x "${PROVISION_SCRIPT}" ]] || fail "Provision script not executable: ${PROVISION_SCRIPT}"
[[ -x "${STACK_SCRIPT}" ]] || fail "Stack script not executable: ${STACK_SCRIPT}"
[[ -x "${DESTROY_SCRIPT}" ]] || fail "Destroy script not executable: ${DESTROY_SCRIPT}"
[[ -x "${BOOTSTRAP_SCRIPT}" ]] || fail "Bootstrap script not executable: ${BOOTSTRAP_SCRIPT}"

require_cmd qm
require_cmd ssh
require_cmd scp

case "${COMMAND}" in
  all)
    log "Running full homelab pipeline: template -> provision -> bootstrap"
    bash "${BUILD_TEMPLATE_SCRIPT}"
    bash "${PROVISION_SCRIPT}"
    run_remote_bootstrap
    ;;
  template)
    log "Running template builder only"
    bash "${BUILD_TEMPLATE_SCRIPT}"
    ;;
  provision)
    log "Running VM provisioning only"
    bash "${PROVISION_SCRIPT}"
    ;;
  bootstrap)
    log "Running bootstrap only"
    run_remote_bootstrap
    ;;
  stack)
    log "Running legacy stack flow"
    bash "${STACK_SCRIPT}"
    ;;
  destroy)
    log "Destroying resources: ${DESTROY_TARGET}"
    bash "${DESTROY_SCRIPT}" "${DESTROY_TARGET}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    fail "Unknown command: ${COMMAND}"
    ;;
esac

log "Pipeline completed successfully"
