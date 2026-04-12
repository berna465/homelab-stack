# homelab-stack

Repository per un homelab single-VM (`homelab-core`) con separazione esplicita tra provisioning compute e deploy applicativo.

## Repository layout (target, con compatibilità legacy)

```text
homelab-stack/
├── ansible/
│   ├── inventories/production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       ├── all.yml
│   │       └── homelab_core.yml
│   ├── playbooks/
│   │   ├── provision.yml
│   │   ├── deploy.yml
│   │   └── site.yml
│   └── roles/
├── stacks/
│   ├── immich/
│   ├── bookstack/
│   ├── journiv/
│   ├── jellyfin/
│   ├── memos/
│   └── whoami/
├── docs/
│   ├── architecture/
│   ├── operations/
│   └── apps/
└── scripts/
```

## Provisioning vs Deploy

- **Provisioning** (`ansible/playbooks/provision.yml`): prepara VM/host baseline, dischi, mount NFS, identity mapping.
- **Deploy** (`ansible/playbooks/deploy.yml`): deploy degli stack applicativi.
- **Site** (`ansible/playbooks/site.yml`): provisioning + deploy in sequenza.

## Comandi principali

```bash
ansible-playbook ansible/playbooks/provision.yml
ansible-playbook ansible/playbooks/deploy.yml
ansible-playbook ansible/playbooks/site.yml
```

### Alias legacy ancora validi

- `playbooks/compute/provision-base.yml`
- `playbooks/stacks/deploy-all-apps.yml`
- `playbooks/deploy-all.yml`

## Config e secrets

Baseline target:

- Repo: `stacks/<app>/.env.example` (non sensibile)
- NAS: `/mnt/nas/data/homelab-config/app-env/<app>.env` (override runtime)
- NAS: `/mnt/nas/data/homelab-config/secrets/<app>/...` (secret file-based)
- Runtime locale: `/data/stacks/<app>/.env` (materializzato da Ansible)

Uso secrets:

- preferire `*_FILE` / Docker secrets dove supportato
- mantenere fallback `.env` dove non ancora supportato

## Variabili: regola pratica

- `all.yml`: sole convenzioni globali (path base, policy mount, UID/GID, timezone, convenzioni config).
- `homelab_core.yml`: specificità nodo (`vm_id`, `vm_name`, `vm_ipconfig0`, stack/path override host-specifici).

## Dove iniziare per aggiungere una nuova app

Vedi: `docs/operations/add-new-stack.md`.
