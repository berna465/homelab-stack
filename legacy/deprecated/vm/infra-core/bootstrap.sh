#!/bin/bash
set -e

curl -fsSL https://get.docker.com | sh
usermod -aG docker bernardo

if [ ! -d /home/bernardo/homelab-stack ]; then
  sudo -u bernardo git clone https://github.com/berna465/homelab-stack /home/bernardo/homelab-stack
fi

cd /home/bernardo/homelab-stack/docker/infra-core

set -o allexport
source /home/bernardo/homelab-stack/config/secrets/home.secrets.env || true
set +o allexport

docker compose up -d

echo "[infra-core] Deploy completato."
