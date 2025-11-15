# Homelab Stack

Repository per creare automaticamente le VM, bootstrap Docker e installare gli stack applicativi.

## Struttura
- `config/environments/*.env` — configurazioni per ambiente
- `config/secrets/*.secrets.env` — password e token (NON committati)
- `vm/<vm>/bootstrap.sh` — script eseguiti dentro alle VM
- `docker/<vm>/docker-compose.yml` — stack applicativi
- `scripts/deploy.sh` — script da eseguire su Proxmox per creare/aggiornare le VM

## Deploy
Sul nodo Proxmox:

cd homelab-stack/scripts
./deploy.sh home

