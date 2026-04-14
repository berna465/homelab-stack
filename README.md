# homelab-stack

Repository per una piattaforma homelab Linux-first con separazione esplicita tra infrastruttura opzionale, foundations della piattaforma e deploy applicativo.

## Architectural Direction

This repository is being refactored toward four explicit layers:

- `infra/`: provisioning e integrazione infrastrutturale environment-specific
- `platform/foundations/`: runtime foundations Linux-native condivise
- `platform/services/`: servizi condivisi di piattaforma
- `apps/`: stack applicativi self-hosted e logica di deploy
- `legacy/`: asset deprecated tenuti solo per migrazione

Guiding principles:

- `The runtime platform must be Linux-native; Proxmox is only one possible infrastructure substrate.`
- `Provisioning is not the same as foundations, and foundations are not the same as application deployment.`

This repository now treats the Ansible-based layered flow as canonical.

## Repository layout

```text
homelab-stack/
├── infra/
│   ├── proxmox/
│   ├── linux-host/
│   └── nas/
├── platform/
│   ├── foundations/
│   └── services/
├── apps/
│   ├── stacks/
│   └── deploy/
├── legacy/
├── ansible/
├── docs/
└── secrets/
```

Documentazione architetturale: `docs/ARCHITECTURE.md`

Legacy assets migrated out of the primary path live under `legacy/deprecated/`.

## Provisioning vs Deploy

- **Provisioning**: prepara substrate e host raggiungibile.
- **Foundations**: prepara il runtime Linux condiviso.
- **Deploy**: deploy degli stack applicativi.
- **Site** (`ansible/playbooks/site.yml`): orchestrazione completa del flusso attuale.

## Comandi principali

```bash
ansible-playbook ansible/playbooks/provision.yml
ansible-playbook ansible/playbooks/deploy.yml
ansible-playbook ansible/playbooks/site.yml
```

Canonical layered entrypoints:

```bash
ansible-playbook infra/proxmox/ansible/playbooks/provision-host.yml
ansible-playbook infra/nas/ansible/playbooks/apply.yml
ansible-playbook platform/foundations/ansible/playbooks/apply.yml
ansible-playbook platform/services/ansible/playbooks/deploy-reverse-proxy.yml
ansible-playbook platform/services/ansible/playbooks/deploy-whoami.yml
ansible-playbook apps/deploy/ansible/playbooks/deploy-immich.yml
ansible-playbook apps/deploy/ansible/playbooks/deploy-bookstack.yml
ansible-playbook apps/deploy/ansible/playbooks/deploy-memos.yml
```

### Resize root disk (step separato, se necessario)

Per evitare problemi durante la creazione VM, l'allargamento del root filesystem non viene eseguito nel provisioning iniziale.
Eseguilo come step successivo esplicito:

```bash
ansible-playbook infra/proxmox/ansible/playbooks/resize-root-disk.yml
```

## Config e secrets

Baseline target:

- Repo: `apps/stacks/<app>/.env.example` (non sensibile)
- NAS: `/mnt/nas/data/homelab-config/app-env/<app>.env` (override runtime)
- NAS: `/mnt/nas/data/homelab-config/secrets/<app>/...` (secret file-based)
- Runtime locale: `/data/stacks/<app>/.env` (materializzato da Ansible)

Uso secrets:

- preferire `*_FILE` / Docker secrets dove supportato
- mantenere fallback `.env` dove non ancora supportato

## Variabili: regola pratica

- `all.yml`: sole convenzioni globali (path base, policy mount, UID/GID, timezone, convenzioni config).
- `homelab_core.yml`: specificità nodo (`vm_id`, `vm_name`, `vm_ipconfig0`, stack/path override host-specifici).

La source of truth runtime per le variabili è `ansible/inventories/production/group_vars/`.

## Dove iniziare per aggiungere una nuova app

Vedi: `docs/operations/add-new-stack.md`.
