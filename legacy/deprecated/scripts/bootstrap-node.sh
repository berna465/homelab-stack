#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-homelab-core}"
REPO_URL="https://github.com/berna465/homelab-stack.git"
REPO_DIR="/opt/homelab-stack"
TARGET_DIR="/opt/homelab-core"

if [[ "${ROLE}" != "homelab-core" ]]; then
  echo "Uso: scripts/bootstrap-node.sh [homelab-core]" >&2
  exit 1
fi

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERROR] Missing command: $1" >&2
    exit 1
  }
}

log "Updating base packages"
apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg git

if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

log "Cloning/updating repository via HTTPS"
if [[ ! -d "${REPO_DIR}" ]]; then
  git clone "${REPO_URL}" "${REPO_DIR}"
else
  git -C "${REPO_DIR}" pull --ff-only
fi

require_cmd docker

[[ -f "${REPO_DIR}/docker/homelab-core/docker-compose.yml" ]] || { echo "[ERROR] Missing compose file" >&2; exit 1; }
[[ -f "${REPO_DIR}/scripts/docker/healthcheck.sh" ]] || { echo "[ERROR] Missing healthcheck script" >&2; exit 1; }
[[ -f "${REPO_DIR}/secrets/homelab-core.env" ]] || { echo "[ERROR] Missing secrets/homelab-core.env" >&2; exit 1; }

log "Installing homelab-core stack files"
mkdir -p "${TARGET_DIR}"
install -m 0644 "${REPO_DIR}/docker/homelab-core/docker-compose.yml" "${TARGET_DIR}/docker-compose.yml"
install -m 0644 "${REPO_DIR}/docker/homelab-core/.env.example" "${TARGET_DIR}/.env.example"
install -m 0755 "${REPO_DIR}/scripts/docker/healthcheck.sh" "${TARGET_DIR}/healthcheck.sh"
install -m 0600 "${REPO_DIR}/secrets/homelab-core.env" "${TARGET_DIR}/.env"

log "Deploying docker compose stack"
cd "${TARGET_DIR}"
docker compose --env-file .env up -d
"${TARGET_DIR}/healthcheck.sh"

log "Bootstrap complete"
