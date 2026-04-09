#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="${1:-$(pwd)}"
cd "${STACK_DIR}"

expected_services="$(docker compose config --services | wc -l | tr -d ' ')"
running_services="$(docker compose ps --status running --services | wc -l | tr -d ' ')"

if [[ "${running_services}" -lt "${expected_services}" ]]; then
  echo "[ERROR] Healthcheck failed: ${running_services}/${expected_services} services are running" >&2
  docker compose ps
  exit 1
fi

echo "[OK] Healthcheck passed: ${running_services}/${expected_services} services are running"
