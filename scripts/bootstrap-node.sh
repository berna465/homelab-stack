#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-}"

if [[ -z "${ROLE}" ]]; then
  echo "Uso: scripts/bootstrap-node.sh <infra|apps>"
  exit 1
fi

# Repo in sola lettura via HTTPS (niente chiavi SSH necessarie)
REPO_URL="https://github.com/berna465/homelab-stack.git"
REPO_DIR="/opt/homelab-stack"

echo "==> Aggiorno pacchetti..."
apt-get update -y
apt-get upgrade -y

echo "==> Installo dipendenze base..."
apt-get install -y ca-certificates curl gnupg git

if ! command -v docker >/dev/null 2>&1; then
  echo "==> Installo Docker..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  . /etc/os-release
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
fi

echo "==> Assicuro l'utente 'bernardo' nel gruppo docker (se esiste)..."
if id bernardo >/dev/null 2>&1; then
  usermod -aG docker bernardo
fi

echo "==> Clono o aggiorno il repository ${REPO_URL}..."
if [[ ! -d "${REPO_DIR}" ]]; then
  git clone "${REPO_URL}" "${REPO_DIR}"
else
  cd "${REPO_DIR}"
  git pull
fi

cd "${REPO_DIR}"

echo "==> Creo rete Docker 'proxy' se non esiste..."
if ! docker network ls --format '{{.Name}}' | grep -q '^proxy$'; then
  docker network create proxy
fi

case "${ROLE}" in
  infra)
    echo "==> Bootstrap ruolo: infra-core"
    if [[ ! -f config/secrets/.env.infra-core ]]; then
      echo "ERRORE: manca config/secrets/.env.infra-core"
      exit 1
    fi
    cd stacks/infra-core
    docker compose pull
    docker compose up -d
    ;;
  apps)
    echo "==> Bootstrap ruolo: apps-core"
    if [[ ! -f config/secrets/.env.apps-core ]]; then
      echo "ERRORE: manca config/secrets/.env.apps-core"
      exit 1
    fi
    cd stacks/apps-core
    docker compose pull
    docker compose up -d
    ;;
  *)
    echo "Ruolo sconosciuto: ${ROLE}"
    exit 1
    ;;
esac
