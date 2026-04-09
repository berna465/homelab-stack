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

resolve_docker_compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
    return 0
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n docker compose version >/dev/null 2>&1; then
    echo "sudo docker compose"
    return 0
  fi

  printf '[ERROR] Docker compose is not accessible for user %s.\n' "$(id -un)" >&2
  printf '[ERROR] Fix by adding user to docker group or enabling passwordless sudo for docker.\n' >&2
  exit 1
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

DOCKER_COMPOSE_CMD="$(resolve_docker_compose_cmd)"
export DOCKER_COMPOSE_CMD

log "Starting docker compose stack"
# shellcheck disable=SC2086
${DOCKER_COMPOSE_CMD} --env-file .env up -d

log "Running stack healthcheck"
"${TARGET_DIR}/healthcheck.sh"

log "Deployment completed"
