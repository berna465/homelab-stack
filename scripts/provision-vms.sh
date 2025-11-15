#!/usr/bin/env bash
set -euo pipefail

# Determina root del repo
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config/homelab.yml"

echo "[INFO] Repo root: ${REPO_ROOT}"
echo "[INFO] Config: ${CONFIG_FILE}"

# Controlli preliminari
if ! command -v yq >/dev/null 2>&1; then
  echo "[ERROR] 'yq' non trovato. Installa yq (es. 'apt install yq' oppure binario standalone)." >&2
  exit 1
fi

if ! command -v qm >/dev/null 2>&1; then
  echo "[ERROR] 'qm' non trovato. Questo script va eseguito sul nodo Proxmox." >&2
  exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "[ERROR] Config file ${CONFIG_FILE} non trovato." >&2
  exit 1
fi

# Legge configurazione globale
ENV_NAME="$(yq -r '.env' "${CONFIG_FILE}")"
PROXMOX_NODE="$(yq -r '.proxmox.node' "${CONFIG_FILE}")"
TEMPLATE_ID="$(yq -r '.proxmox.template_id' "${CONFIG_FILE}")"
PVE_STORAGE="$(yq -r '.proxmox.storage' "${CONFIG_FILE}")"
PVE_BRIDGE_LAN="$(yq -r '.proxmox.bridge_lan' "${CONFIG_FILE}")"
PVE_BRIDGE_INTERNAL="$(yq -r '.proxmox.bridge_internal' "${CONFIG_FILE}")"
PVE_BRIDGE_MGMT="$(yq -r '.proxmox.bridge_mgmt' "${CONFIG_FILE}")"
SSH_KEY_PATH="$(yq -r '.proxmox.ssh_key_path' "${CONFIG_FILE}")"
CI_USER="$(yq -r '.proxmox.ci_user // "bernardo"' "${CONFIG_FILE}")"

echo "[INFO] Ambiente: ${ENV_NAME}"
echo "[INFO] Nodo Proxmox: ${PROXMOX_NODE}"
echo "[INFO] Template ID: ${TEMPLATE_ID}"
echo "[INFO] Storage: ${PVE_STORAGE}"
echo "[INFO] Bridges: LAN=${PVE_BRIDGE_LAN}, INTERNAL=${PVE_BRIDGE_INTERNAL}, MGMT=${PVE_BRIDGE_MGMT}"
echo "[INFO] SSH key: ${SSH_KEY_PATH}"
echo "[INFO] Cloud-init user: ${CI_USER}"

if [[ -z "${SSH_KEY_PATH}" || "${SSH_KEY_PATH}" == "null" ]]; then
  echo "[ERROR] ssh_key_path non impostato in ${CONFIG_FILE}" >&2
  exit 1
fi

if [[ ! -f "${SSH_KEY_PATH}" ]]; then
  echo "[ERROR] SSH key ${SSH_KEY_PATH} non trovata." >&2
  exit 1
fi

# Elenco VM definite nel YAML
mapfile -t VM_NAMES < <(yq -r '.vms | keys[]' "${CONFIG_FILE}")
if [[ ${#VM_NAMES[@]} -eq 0 ]]; then
  echo "[ERROR] Nessuna VM definita in .vms nel file ${CONFIG_FILE}" >&2
  exit 1
fi

for VM_NAME in "${VM_NAMES[@]}"; do
  echo
  echo "=== Provisioning VM: ${VM_NAME} ==="

  VMID="$(yq -r ".vms[\"${VM_NAME}\"].vmid" "${CONFIG_FILE}")"
  HOSTNAME="$(yq -r ".vms[\"${VM_NAME}\"].hostname" "${CONFIG_FILE}")"
  CPUS="$(yq -r ".vms[\"${VM_NAME}\"].cpu" "${CONFIG_FILE}")"
  MEM_MB="$(yq -r ".vms[\"${VM_NAME}\"].memory_mb" "${CONFIG_FILE}")"
  DISK_GB="$(yq -r ".vms[\"${VM_NAME}\"].disk_gb" "${CONFIG_FILE}")"

  IP_MGMT="$(yq -r ".vms[\"${VM_NAME}\"].ip_mgmt // \"null\"" "${CONFIG_FILE}")"
  GW_MGMT="$(yq -r ".vms[\"${VM_NAME}\"].gw_mgmt // \"null\"" "${CONFIG_FILE}")"
  IP_INTERNAL="$(yq -r ".vms[\"${VM_NAME}\"].ip_internal // \"null\"" "${CONFIG_FILE}")"
  GW_INTERNAL="$(yq -r ".vms[\"${VM_NAME}\"].gw_internal // \"null\"" "${CONFIG_FILE}")"

  if [[ -z "${VMID}" || "${VMID}" == "null" ]]; then
    echo "[ERROR] vmid mancante per VM ${VM_NAME}" >&2
    continue
  fi

  # Clone solo se la VM non esiste già
  if ! qm status "${VMID}" >/dev/null 2>&1; then
    echo "[INFO] Creo VM ${VMID} (${VM_NAME}) da template ${TEMPLATE_ID}..."
    qm clone "${TEMPLATE_ID}" "${VMID}" --name "${HOSTNAME}" --full true --storage "${PVE_STORAGE}"
  else
    echo "[INFO] VM ${VMID} (${VM_NAME}) esiste già, salto clone."
  fi

  echo "[INFO] Configuro CPU/RAM..."
  qm set "${VMID}" --cores "${CPUS}" --memory "${MEM_MB}"

  echo "[INFO] Configuro rete..."
  # Se c'è IP di management, usiamo:
  #   net0 -> MGMT, net1 -> INTERNAL
  # altrimenti solo net0 su INTERNAL
  if [[ "${IP_MGMT}" != "null" ]]; then
    qm set "${VMID}" --net0 "virtio,bridge=${PVE_BRIDGE_MGMT}" --net1 "virtio,bridge=${PVE_BRIDGE_INTERNAL}"
  else
    qm set "${VMID}" --net0 "virtio,bridge=${PVE_BRIDGE_INTERNAL}"
  fi

  echo "[INFO] Configuro cloud-init (utente ${CI_USER}, SSH key, IP)..."
  CI_ARGS=(--ciuser "${CI_USER}" --sshkey "${SSH_KEY_PATH}")

  # ipconfig per management e internal
  if [[ "${IP_MGMT}" != "null" ]]; then
    IPCONF0="ip=${IP_MGMT}"
    if [[ "${GW_MGMT}" != "null" ]]; then
      IPCONF0+=",gw=${GW_MGMT}"
    fi
    CI_ARGS+=(--ipconfig0 "${IPCONF0}")
  fi

  if [[ "${IP_INTERNAL}" != "null" ]]; then
    if [[ "${IP_MGMT}" != "null" ]]; then
      IPCONF1="ip=${IP_INTERNAL}"
      if [[ "${GW_INTERNAL}" != "null" ]]; then
        IPCONF1+=",gw=${GW_INTERNAL}"
      fi
      CI_ARGS+=(--ipconfig1 "${IPCONF1}")
    else
      IPCONF0="ip=${IP_INTERNAL}"
      if [[ "${GW_INTERNAL}" != "null" ]]; then
        IPCONF0+=",gw=${GW_INTERNAL}"
      fi
      CI_ARGS+=(--ipconfig0 "${IPCONF0}")
    fi
  fi

  qm set "${VMID}" "${CI_ARGS[@]}"

  echo "[INFO] VM ${VMID} (${VM_NAME}) pronta. Puoi avviarla con:"
  echo "       qm start ${VMID}"
done
