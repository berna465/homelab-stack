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

if [[ ! -f "${CONFIG_FILE}" ]]; then
  fail "Configuration file not found: ${CONFIG_FILE}"
fi

# shellcheck disable=SC1090
source "${CONFIG_FILE}"

require_cmd qm
require_cmd pvesm
require_cmd wget
require_cmd qemu-img

TEMPLATE_OS="${TEMPLATE_OS:-debian}"
TEMPLATE_ID="${TEMPLATE_ID:-902}"
TEMPLATE_NAME="${TEMPLATE_NAME:-${TEMPLATE_OS}-cloud-template}"
TEMPLATE_MEMORY_MB="${TEMPLATE_MEMORY_MB:-2048}"
TEMPLATE_CORES="${TEMPLATE_CORES:-2}"
TEMPLATE_BRIDGE="${TEMPLATE_BRIDGE:-${VM_BRIDGE:-vmbr0}}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-${PVE_STORAGE:-local-lvm}}"
TEMPLATE_SNIPPET_STORAGE="${TEMPLATE_SNIPPET_STORAGE:-local}"
FORCE_RECREATE="${FORCE_RECREATE:-0}"

case "${TEMPLATE_OS}" in
  debian)
    IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
    IMAGE_FILE="debian-12-genericcloud-amd64.qcow2"
    DEFAULT_CIUSER="debian"
    ;;
  ubuntu)
    IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    IMAGE_FILE="ubuntu-24.04-server-cloudimg-amd64.img"
    DEFAULT_CIUSER="ubuntu"
    ;;
  *)
    fail "Unsupported TEMPLATE_OS='${TEMPLATE_OS}'. Use 'debian' or 'ubuntu'."
    ;;
esac

TEMPLATE_CIUSER="${TEMPLATE_CIUSER:-${DEFAULT_CIUSER}}"
IMAGE_DIR="/var/lib/vz/template/qemu"
IMAGE_PATH="${IMAGE_DIR}/${IMAGE_FILE}"
SNIPPET_DIR="/var/lib/vz/snippets"
SNIPPET_FILE="template-hardening-${TEMPLATE_ID}.yaml"
SNIPPET_PATH="${SNIPPET_DIR}/${SNIPPET_FILE}"

mkdir -p "${IMAGE_DIR}" "${SNIPPET_DIR}"

if qm status "${TEMPLATE_ID}" >/dev/null 2>&1; then
  if [[ "${FORCE_RECREATE}" == "1" ]]; then
    log "Template VMID ${TEMPLATE_ID} already exists. Destroying because FORCE_RECREATE=1"
    qm destroy "${TEMPLATE_ID}" --purge
  else
    log "Template VMID ${TEMPLATE_ID} already exists. Nothing to do."
    exit 0
  fi
fi

if [[ ! -f "${IMAGE_PATH}" ]]; then
  log "Downloading cloud image: ${IMAGE_URL}"
  wget -q --show-progress -O "${IMAGE_PATH}" "${IMAGE_URL}"
else
  log "Cloud image already present: ${IMAGE_PATH}"
fi

cat > "${SNIPPET_PATH}" <<YAML
#cloud-config
package_update: true
package_upgrade: false
packages:
  - qemu-guest-agent
ssh_pwauth: false
disable_root: true
users:
  - default
  - name: ${TEMPLATE_CIUSER}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
runcmd:
  - systemctl enable --now qemu-guest-agent
  - timedatectl set-timezone UTC
YAML

log "Validating cloud image format"
qemu-img info "${IMAGE_PATH}" >/dev/null

log "Creating VM ${TEMPLATE_ID} (${TEMPLATE_NAME})"
qm create "${TEMPLATE_ID}" \
  --name "${TEMPLATE_NAME}" \
  --ostype l26 \
  --cpu host \
  --memory "${TEMPLATE_MEMORY_MB}" \
  --cores "${TEMPLATE_CORES}" \
  --net0 "virtio,bridge=${TEMPLATE_BRIDGE}" \
  --agent 1 \
  --scsihw virtio-scsi-pci \
  --serial0 socket \
  --vga serial0

log "Importing cloud image into storage ${TEMPLATE_STORAGE}"
qm importdisk "${TEMPLATE_ID}" "${IMAGE_PATH}" "${TEMPLATE_STORAGE}" >/dev/null

qm set "${TEMPLATE_ID}" \
  --scsi0 "${TEMPLATE_STORAGE}:vm-${TEMPLATE_ID}-disk-0" \
  --ide2 "${TEMPLATE_STORAGE}:cloudinit" \
  --boot c \
  --bootdisk scsi0 \
  --ciuser "${TEMPLATE_CIUSER}" \
  --ipconfig0 ip=dhcp \
  --cicustom "user=${TEMPLATE_SNIPPET_STORAGE}:snippets/${SNIPPET_FILE}"

if [[ -n "${VM_SSH_PUBLIC_KEY_FILE:-}" && -f "${VM_SSH_PUBLIC_KEY_FILE}" ]]; then
  qm set "${TEMPLATE_ID}" --sshkey "${VM_SSH_PUBLIC_KEY_FILE}"
fi

log "Converting VM ${TEMPLATE_ID} to template"
qm template "${TEMPLATE_ID}"

log "Template ready: VMID ${TEMPLATE_ID}, OS ${TEMPLATE_OS}, name ${TEMPLATE_NAME}"
