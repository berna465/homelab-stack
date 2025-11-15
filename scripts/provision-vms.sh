#!/usr/bin/env bash
set -euo pipefail

# Script: provision-vms.sh
# Scopo: leggere config/homelab.yml e creare/aggiornare le VM
# NOTE: per ora è solo uno scheletro con i comandi base.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config/homelab.yml"

echo "[INFO] Repo root: ${REPO_ROOT}"
echo "[INFO] Config: ${CONFIG_FILE}"

if ! command -v yq >/dev/null 2>&1; then
  echo "[ERROR] yq non trovato. Installa yq (es. 'apt install yq' o binario standalone)." >&2
  exit 1
fi

ENV_NAME="${1:-lab}"
echo "[INFO] Ambiente: ${ENV_NAME}"

# TODO:
#  - leggere host Proxmox, node, user, token, ecc.
#  - per ogni VM (infra-core, apps-core):
#     - clonare template 902
#     - impostare CPU/RAM/disk
#     - configurare cloud-init (IP mgmt + internal)
#     - avviare VM

echo "[TODO] implementare la logica di provisioning VM usando 'qm' e le info in ${CONFIG_FILE}"
