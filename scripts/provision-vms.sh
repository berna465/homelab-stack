#!/usr/bin/env bash
set -euo pipefail

# Provisions homelab VMs only (no docker deploy).
# Uses the same core logic as scripts/proxmox/stack.sh with SKIP_DEPLOY=1.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK_SCRIPT="${REPO_ROOT}/scripts/proxmox/stack.sh"

if [[ ! -x "${STACK_SCRIPT}" ]]; then
  echo "[ERROR] Missing executable: ${STACK_SCRIPT}" >&2
  exit 1
fi

echo "[INFO] Provisioning VM(s) only via stack.sh (SKIP_DEPLOY=1)"
SKIP_DEPLOY=1 bash "${STACK_SCRIPT}"
