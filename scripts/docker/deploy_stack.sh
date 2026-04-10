#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-/tmp/homelab-stack}"
TARGET_DIR="${2:-/opt/homelab-core}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

require_file() {
  local file_path="$1"
  [[ -f "${file_path}" ]] || {
    printf '[ERROR] Required file not found: %s\n' "${file_path}" >&2
    exit 1
  }
}

compose_cmd() {
  if docker ps >/dev/null 2>&1; then
    docker compose "$@"
    return 0
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n docker ps >/dev/null 2>&1; then
    sudo -n docker compose "$@"
    return 0
  fi

  printf '[ERROR] Docker compose failed both as user (%s) and via passwordless sudo.\n' "$(id -un)" >&2
  printf '[ERROR] Configure docker group membership or passwordless sudo for docker.\n' >&2
  return 1
}

require_file "${SOURCE_DIR}/docker-compose.yml"
require_file "${SOURCE_DIR}/healthcheck.sh"
require_file "${SOURCE_DIR}/homelab-core.env"

mkdir -p "${TARGET_DIR}"
install -m 0644 "${SOURCE_DIR}/docker-compose.yml" "${TARGET_DIR}/docker-compose.yml"
install -m 0644 "${SOURCE_DIR}/.env.example" "${TARGET_DIR}/.env.example"
install -m 0755 "${SOURCE_DIR}/healthcheck.sh" "${TARGET_DIR}/healthcheck.sh"
install -m 0600 "${SOURCE_DIR}/homelab-core.env" "${TARGET_DIR}/.env"

cd "${TARGET_DIR}"

log "Starting docker compose stack"
compose_cmd --env-file .env up -d

log "Running stack healthcheck"
"${TARGET_DIR}/healthcheck.sh"

log "Deployment completed"
