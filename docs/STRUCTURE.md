# Struttura repository (refactor mirato)

Layout pensato per separare chiaramente:

1. **provisioning compute/host baseline**
2. **deploy degli stack applicativi**

## Directory principali

```text
homelab-stack/
├── group_vars/
│   ├── all.yml
│   └── homelab_core.yml
├── inventory/
├── playbooks/
│   ├── compute/
│   │   └── provision-base.yml
│   ├── stacks/
│   │   ├── deploy-all-apps.yml
│   │   └── deploy-immich-only.yml
│   ├── deploy-all.yml
│   ├── deploy-immich.yml
│   ├── deploy-journiv.yml
│   ├── deploy-bookstack.yml
│   ├── deploy-jellyfin.yml
│   └── ... (playbook legacy mantenuti per compatibilità)
├── files/homelab-core/<app>/
│   ├── docker-compose.yml
│   └── .env.example
├── docs/
│   ├── STRUCTURE.md
│   ├── VARIABLES.md
│   ├── CONFIG-SECRETS.md
│   └── OPERATIONS.md
└── README.md
```

## Principio operativo

- `playbooks/compute/*`: prepara host/VM, storage, mount NFS, identity/permessi.
- `playbooks/stacks/*`: deploy app stack, senza riconfigurare compute.
- I playbook root esistenti restano usabili per non rompere workflow attuali.
