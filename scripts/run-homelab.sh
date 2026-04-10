#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config/homelab.env"
BUILD_TEMPLATE_SCRIPT="${REPO_ROOT}/scripts/proxmox/build_template.sh"
STACK_SCRIPT="${REPO_ROOT}/scripts/proxmox/stack.sh"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<USAGE
Usage: bash scripts/run-homelab.sh [all|template|stack]

Commands:
  all       Build/refresh template, then provision+deploy stack (default)
  template  Build/refresh template only
  stack     Provision VM + deploy stack only
USAGE
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

COMMAND="${1:-all}"

[[ -f "${CONFIG_FILE}" ]] || fail "Configuration file not found: ${CONFIG_FILE}"
[[ -x "${BUILD_TEMPLATE_SCRIPT}" ]] || fail "Template builder not executable: ${BUILD_TEMPLATE_SCRIPT}"
[[ -x "${STACK_SCRIPT}" ]] || fail "Stack script not executable: ${STACK_SCRIPT}"

require_cmd qm

case "${COMMAND}" in
  all)
    log "Running full homelab pipeline: template + stack"
    bash "${BUILD_TEMPLATE_SCRIPT}"
    bash "${STACK_SCRIPT}"
    ;;
  template)
    log "Running template builder only"
    bash "${BUILD_TEMPLATE_SCRIPT}"
    ;;
  stack)
    log "Running stack provisioning/deploy only"
    bash "${STACK_SCRIPT}"
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
