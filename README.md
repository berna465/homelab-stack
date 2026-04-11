# homelab-stack (final storage model)

Minimal Ansible IaC for one Proxmox VM (`homelab-core`) using this source-of-truth storage model:

- **VM local `/data`** = technical persistence only (DB/cache/runtime/stacks)
- **NAS via NFS `/mnt/nas`** = persistent app content and backups

## Current infrastructure

- Proxmox host: `proxmox.home.bernardolab.it`
- VM name: `homelab-core`
- VMID: `210`
- VM IP: `192.168.178.210`

## Final storage strategy

### Local VM storage (`/data`)

Use only for:

- `/data/stacks/<app>`
- `/data/db/<db-or-app>`
- `/data/cache/<cache-or-app>`
- `/data/runtime/<app>`
- `/data/backups-local/...` (optional temporary local backups)

### NAS NFS mounts (`/mnt/nas/...`)

Configured shares:

- `/mnt/nas/data` -> export `/DATA`
- `/mnt/nas/media` -> export `/Media`
- `/mnt/nas/backups` -> export `/Backups`
- `/mnt/nas/clouds` -> export `/Clouds`

#### Important NAS rule

`/mnt/nas/media` is treated as a media-library share and may not be writable at root.
Do **not** create generic app directories there.

For writable app content, use:

- `/mnt/nas/data/apps/<app>/...`

For backups, use:

- `/mnt/nas/backups/<app>/...`

## Repository structure

```text
homelab-stack/
├── ansible.cfg
├── inventory/
├── group_vars/
├── playbooks/
├── files/
├── README.md
└── AGENTS.md
```

## Clean rebuild flow

Run from repo root:

1. Provision VM (create-only)

```bash
ansible-playbook playbooks/provision.yml
```

2. Attach local data disk on Proxmox

```bash
ansible-playbook playbooks/attach-data-disk.yml
```

3. Prepare and mount local data disk at `/data`

```bash
ansible-playbook playbooks/prepare-data-disk.yml
```

4. Mount NAS NFS shares

```bash
ansible-playbook playbooks/mount-nas-nfs.yml
```

5. Deploy smoke-test stack

```bash
ansible-playbook playbooks/deploy.yml
curl -i http://192.168.178.210:8080
```

6. Deploy app stacks one-by-one

```bash
ansible-playbook playbooks/deploy-memos.yml
ansible-playbook playbooks/deploy-journiv.yml
```

## App conventions

### whoami

- Smoke test only
- Minimal footprint in `/data/stacks/whoami`

### memos

- Stack: `/data/stacks/memos`
- Local state: `/data/runtime/memos`
- Backups/exports: `/mnt/nas/backups/memos`

### journiv

- Stack: `/data/stacks/journiv`
- Postgres: `/data/db/journiv-postgres`
- Valkey: `/data/cache/journiv-valkey`
- Runtime: `/data/runtime/journiv`
- Writable app content: `/mnt/nas/data/apps/journiv`
- Backups: `/mnt/nas/backups/journiv`

`deploy-journiv.yml` validates NAS content/backup paths exist and are writable before deployment.


## Configuration precedence (repo defaults + NAS overrides)

The repository remains the default source of truth for:

- playbooks
- templates and compose files
- default `group_vars`
- `.env.example` files

Optional runtime overrides can be stored on NAS under:

- `/mnt/nas/data/homelab-config/group_vars/`
- `/mnt/nas/data/homelab-config/secrets/`
- `/mnt/nas/data/homelab-config/app-env/`

Behavior:

1. Repo defaults are always loaded.
2. If NAS override files exist, they are merged on top of defaults.
3. If NAS app env files exist (`app-env/memos.env`, `app-env/journiv.env`), deploy playbooks use them.
4. If NAS overrides are missing, deployment continues with repo defaults.

This keeps bootstrap/rebuild functional from the repo alone while allowing environment-specific NAS overrides.

## Guardrails

- Do not store DB/cache on NFS.
- Do not use `/opt/...` for app storage.
- Do not treat VM root filesystem as persistent app storage.
- Keep deployment simple: one VM, one app stack at a time.
