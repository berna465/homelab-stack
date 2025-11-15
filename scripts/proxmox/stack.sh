#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CONFIG_FILE="${ROOT_DIR}/config/homelab.env"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "ERRORE: file di configurazione non trovato: ${CONFIG_FILE}" >&2
  exit 1
fi

# Carico configurazione
# shellcheck disable=SC1090
source "${CONFIG_FILE}"

echo "== Homelab stack =="
echo " Ambiente: ${HOMELAB_ENV}"
echo " Nodo Proxmox: ${PVE_NODE_NAME}"
echo

# TODO: in futuro qui:
# 1. Validare prerequisiti (qm, pvesh, etc.)
# 2. Creare/aggiornare VM infra-core da template
# 3. Creare/aggiornare VM apps-core da template
# 4. Configurare cloud-init (rete, hostname, ssh key)
# 5. Eseguire post-hook install dentro le VM (via qm guest exec/ssh)

echo "[TODO] Qui andrà la logica per creare e configurare:"
echo " - VM ${INFRA_CORE_VMID} / ${INFRA_CORE_NAME}"
echo " - VM ${APPS_CORE_VMID} / ${APPS_CORE_NAME}"
