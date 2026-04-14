# Operazioni: deploy, nuova app, troubleshooting

## Provisioning compute vs deploy stack

### Provisioning compute (host baseline)

```bash
ansible-playbook playbooks/compute/provision-base.yml
```

Include:
- provisioning VM
- data disk attach/prepare
- mount NFS
- identity/permessi
- preparazione path NAS

### Deploy stack applicativi

```bash
ansible-playbook playbooks/stacks/deploy-all-apps.yml
```

Oppure singolo stack (esempio Immich):

```bash
ansible-playbook playbooks/stacks/deploy-immich-only.yml
```

## Come aggiungere una nuova app

1. creare `files/homelab-core/<app>/docker-compose.yml`
2. creare `files/homelab-core/<app>/.env.example`
3. aggiungere variabili `<app>_*` in `group_vars/homelab_core.yml`
4. creare `playbooks/deploy-<app>.yml`
5. opzionale: aggiungere wrapper in `playbooks/stacks/`
6. documentare path NAS richiesti e healthcheck

## Troubleshooting rapido

### env
- verificare se è presente `app-env/<app>.env` sul NAS
- controllare che `.env` runtime venga generato/copiato correttamente in `/data/stacks/<app>/`

### secrets
- verificare leggibilità file secrets dal contesto utente deploy
- evitare secret direttamente in `docker-compose.yml`

### permessi/NFS
- se write probe fallisce, controllare mapping UID/GID lato NAS
- verificare che i path richiesti esistano (`/mnt/nas/data/apps/...`, `/mnt/nas/backups/...`)
- ricordare che root su NFS può essere squashato
