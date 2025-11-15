#!/usr/bin/env bash
set -euo pipefail

# Script entrypoint per il mio homelab.
# TODO: implementare step-by-step:
#  - lettura config YAML
#  - creazione VM da template
#  - configurazione cloud-init
#  - deploy docker-compose su infra-core e apps-core
#  - post-hook di verifica

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ENV_NAME="${1:-prod}"
CONFIG_FILE="${REPO_ROOT}/config/homelab.config.yaml"

echo "=== homelab-stack bootstrap ==="
echo "Environment: ${ENV_NAME}"
echo "Config file: ${CONFIG_FILE}"
echo

if ! command -v yq >/dev/null 2>&1; then
  echo "ERRORE: 'yq' non trovato. Installalo (es. 'apt install yq' oppure 'snap install yq')."
  exit 1
fi

if ! command -v qm >/dev/null 2>&1; then
  echo "ERRORE: questo script va eseguito su un nodo Proxmox (comando 'qm' mancante)."
  exit 1
fi

if [ ! -f "${CONFIG_FILE}" ]; then
  echo "ERRORE: file di config non trovato: ${CONFIG_FILE}"
  exit 1
fi

# Esempio di lettura dal config (prova che yq funziona)
PROXMOX_NODE=$(yq ".environments.${ENV_NAME}.proxmox.node_name" "${CONFIG_FILE}")
TEMPLATE_ID=$(yq ".environments.${ENV_NAME}.proxmox.template_vm_id" "${CONFIG_FILE}")

echo "Proxmox node: ${PROXMOX_NODE}"
echo "Template ID : ${TEMPLATE_ID}"
echo

echo "Per ora lo script è solo uno scheletro."
echo "Prossimi passi:"
echo "  - implementare funzione create_vm_infra_core"
echo "  - implementare funzione create_vm_apps_core"
echo "  - generare cloud-init per rete + utente bernardo"
echo "  - clonare e/o deployare i docker-compose su ciascuna VM"
