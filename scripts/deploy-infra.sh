#!/usr/bin/env bash
set -euo pipefail

# Script: deploy-infra.sh
# Scopo: deployare stack docker su infra-core e apps-core
# NOTE: per ora solo scheletro.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config/homelab.yml"

ENV_NAME="${1:-lab}"
echo "[INFO] Ambiente: ${ENV_NAME}"

if ! command -v yq >/dev/null 2>&1; then
  echo "[ERROR] yq non trovato. Installa yq." >&2
  exit 1
fi

INFRA_IP="$(yq ".environments.${ENV_NAME}.vms.\"infra-core\".mgmt_ip" "${CONFIG_FILE}")"
APPS_IP="$(yq ".environments.${ENV_NAME}.vms.\"apps-core\".internal_ip" "${CONFIG_FILE}")"

echo "[INFO] infra-core @ ${INFRA_IP}"
echo "[INFO] apps-core  @ ${APPS_IP}"

# TODO:
#  - copiare questa repo sulle VM (git clone o rsync)
#  - su infra-core: docker compose up -d nello stack infra-core
#  - su apps-core: docker compose up -d nello stack apps-core

echo "[TODO] implementare ssh/rsync + docker compose per infra-core e apps-core"
