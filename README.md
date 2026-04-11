# homelab-stack (clean rebuild model)

Minimal Ansible infrastructure-as-code for one Proxmox VM (`homelab-core`) with explicit storage layering:

- **VM local `/data`** for technical persistence (databases, cache, runtime state, stack directories)
- **NAS `/mnt/nas` via NFS** for durable user content (media, documents, exports, backups)

## Architecture targets

- Proxmox host: `proxmox.home.bernardolab.it`
- Template VMID: `902`
- Target VM:
  - VMID: `210`
  - Name: `homelab-core`
  - IP: `192.168.178.210/24`
  - Gateway: `192.168.178.1`
  - Cloud-init user: `debian`

Design principle:

- The VM is the engine (`/data`)
- The NAS is the memory (`/mnt/nas`)

## Repository structure

```text
homelab-stack/
├── ansible.cfg
├── inventory/
│   └── hosts.yml
├── group_vars/
│   ├── all.yml
│   └── homelab_core.yml
├── playbooks/
│   ├── provision.yml
│   ├── attach-data-disk.yml
│   ├── prepare-data-disk.yml
│   ├── mount-nas-nfs.yml
│   ├── deploy.yml                 # whoami smoke test
│   ├── deploy-memos.yml
│   └── deploy-journiv.yml
└── files/
    └── homelab-core/
        ├── docker-compose.yml
        ├── memos/
        └── journiv/
```

## Storage model

### Local VM data disk mounted at `/data`

Used for:

- `/data/stacks` (compose stacks)
- `/data/db` (PostgreSQL/MariaDB)
- `/data/cache` (Redis/Valkey)
- `/data/runtime` (runtime state)
- `/data/backups-local` (local technical snapshots)

### NAS NFS mounts under `/mnt/nas`

Used for:

- `/mnt/nas/apps`
- `/mnt/nas/media`
- `/mnt/nas/documents`
- `/mnt/nas/photos`
- `/mnt/nas/backups`
- `/mnt/nas/shared`

`group_vars/all.yml` contains explicit placeholders for `nas_nfs_server` and export paths; replace them before running NFS mount playbooks.

## Prerequisites

- Ansible installed on control machine
- SSH access to Proxmox as `root`
- SSH public key locally available (default `~/.ssh/id_rsa.pub`)
- Template VM `902` present on Proxmox with cloud-init enabled
- NAS reachable from VM with NFS exports configured

## Clean rebuild execution order

Run commands from repository root.

### 1) Provision VM (create-only)

```bash
ansible-playbook playbooks/provision.yml
```

### 2) Attach dedicated local data disk on Proxmox

```bash
ansible-playbook playbooks/attach-data-disk.yml
```

### 3) Prepare and mount local data disk at `/data`

```bash
ansible-playbook playbooks/prepare-data-disk.yml
```

### 4) Mount NAS NFS shares under `/mnt/nas/...`

```bash
ansible-playbook playbooks/mount-nas-nfs.yml
```

### 5) Deploy whoami smoke-test stack

```bash
ansible-playbook playbooks/deploy.yml
curl -i http://192.168.178.210:8080
```

### 6) Deploy app stacks one by one

Memos:

```bash
ansible-playbook playbooks/deploy-memos.yml
curl -i http://192.168.178.210:5230/api/v1/status
```

Journiv:

```bash
ansible-playbook playbooks/deploy-journiv.yml
curl -i http://192.168.178.210:8010/
```

## App storage conventions

### whoami

- Smoke test only
- Minimal local footprint in `/data/stacks/whoami`

### memos

- Local runtime state: `/data/runtime/memos`
- Stack path: `/data/stacks/memos`
- NAS backup/export target: `/mnt/nas/backups/memos`

### journiv

- App runtime local: `/data/runtime/journiv`
- PostgreSQL local: `/data/db/journiv-postgres`
- Valkey local: `/data/cache/journiv-valkey`
- Media/content on NAS: `/mnt/nas/media/journiv`
- Backups/exports on NAS: `/mnt/nas/backups/journiv`

## Notes

- Keep stacks independent and deploy one app at a time.
- No reverse proxy/auth layer in this baseline.
- Do not place databases or cache services on NFS.
