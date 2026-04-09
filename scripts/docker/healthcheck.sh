#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="${1:-$(pwd)}"
cd "${STACK_DIR}"

DOCKER_COMPOSE_CMD="${DOCKER_COMPOSE_CMD:-docker compose}"

expected_services="$(eval "${DOCKER_COMPOSE_CMD} config --services" | wc -l | tr -d ' ')"
running_services="$(eval "${DOCKER_COMPOSE_CMD} ps --status running --services" | wc -l | tr -d ' ')"

if [[ "${running_services}" -lt "${expected_services}" ]]; then
  echo "[ERROR] Healthcheck failed: ${running_services}/${expected_services} services are running" >&2
  eval "${DOCKER_COMPOSE_CMD} ps"
  exit 1
fi

echo "[OK] Healthcheck passed: ${running_services}/${expected_services} services are running"
