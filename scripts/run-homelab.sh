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

validate_ssh_key_pair() {
  local private_key="$1"
  local public_key="$2"
  local derived_public
  local expected_public

  [[ -f "${private_key}" ]] || fail "SSH private key not found: ${private_key}"
  [[ -f "${public_key}" ]] || fail "SSH public key not found: ${public_key}"

  derived_public="$(ssh-keygen -y -f "${private_key}" 2>/dev/null)" || fail "Unable to read SSH private key: ${private_key}"
  expected_public="$(awk '{print $1" "$2}' "${public_key}")"

  if [[ "${derived_public}" != "${expected_public}" ]]; then
    fail "Configured SSH key pair mismatch: ${private_key} does not match ${public_key}"
  fi
}

build_ssh_opts() {
  local key="$1"
  local port="$2"
  SSH_OPTS=(
    -i "${key}"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o BatchMode=yes
    -o ConnectTimeout=3
    -o ConnectionAttempts=1
    -o PreferredAuthentications=publickey
    -p "${port}"
  )
  SCP_OPTS=(
    -i "${key}"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o ConnectTimeout=3
    -o ConnectionAttempts=1
    -P "${port}"
  )
}

resolve_remote_user() {
  local host="$1"
  local candidate

  for candidate in "${VM_BOOTSTRAP_USER:-}" "${VM_CIUSER}" "${TEMPLATE_CIUSER:-}" ubuntu debian; do
    [[ -n "${candidate}" ]] || continue
    if ssh "${SSH_OPTS[@]}" "${candidate}@${host}" "true" >/dev/null 2>&1; then
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
  local pubkey="${VM_SSH_PUBLIC_KEY_FILE:-${HOME}/.ssh/id_rsa.pub}"
  local user=""
  local attempted_users=()
  local candidate

  validate_ssh_key_pair "${key}" "${pubkey}"
  build_ssh_opts "${key}" "${port}"

  log "Waiting for SSH port on ${host}:${port}"
  for _ in $(seq 1 90); do
    if nc -z "${host}" "${port}" >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
  nc -z "${host}" "${port}" >/dev/null 2>&1 || fail "SSH port ${host}:${port} is not reachable"

  if [[ -n "${VM_BOOTSTRAP_USER:-}" ]]; then
    attempted_users+=("${VM_BOOTSTRAP_USER}")
  fi
  for candidate in "${VM_CIUSER}" "${TEMPLATE_CIUSER:-}" ubuntu debian; do
    [[ -n "${candidate}" ]] || continue
    if [[ " ${attempted_users[*]} " != *" ${candidate} "* ]]; then
      attempted_users+=("${candidate}")
    fi
  done

  log "Waiting for SSH key authentication on ${host}:${port}"
  for attempt in $(seq 1 120); do
    if user="$(resolve_remote_user "${host}")"; then
      break
    fi

    if (( attempt % 10 == 0 )); then
      log "Still waiting for SSH auth (${attempt}/120)"
    fi
    sleep 2
  done

  [[ -n "${user}" ]] || fail "Unable to authenticate on ${host} for bootstrap (users tried: ${attempted_users[*]}). Check VM_CIUSER/VM_BOOTSTRAP_USER, key pair, and cloud-init status."

  local target="${user}@${host}"

  log "Copying bootstrap-node.sh to ${target}"
  scp "${SCP_OPTS[@]}" "${BOOTSTRAP_SCRIPT}" "${target}:/tmp/bootstrap-node.sh"

  log "Running bootstrap-node.sh remotely"
  ssh "${SSH_OPTS[@]}" "${target}" "chmod +x /tmp/bootstrap-node.sh && (sudo -n bash /tmp/bootstrap-node.sh homelab-core || bash /tmp/bootstrap-node.sh homelab-core)"
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
require_cmd ssh-keygen
require_cmd nc

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
