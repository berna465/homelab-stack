#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="${1:-$(pwd)}"
cd "${STACK_DIR}"

compose_cmd() {
  if docker compose "$@"; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n docker compose "$@"; then
    return 0
  fi

  echo "[ERROR] Docker compose is not accessible for healthcheck" >&2
  return 1
}

expected_services="$(compose_cmd config --services | wc -l | tr -d ' ')"
running_services="$(compose_cmd ps --status running --services | wc -l | tr -d ' ')"

if [[ "${running_services}" -lt "${expected_services}" ]]; then
  echo "[ERROR] Healthcheck failed: ${running_services}/${expected_services} services are running" >&2
  compose_cmd ps
  exit 1
fi

echo "[OK] Healthcheck passed: ${running_services}/${expected_services} services are running"
