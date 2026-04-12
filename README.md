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

## VM/NFS identity model (UID/GID alignment)

NFS write access is validated using numeric identity mapping (UID/GID), not usernames.

Repository defaults define:

- deploy/login user on VM: `homelab_vm_deploy_user` (default `debian`)
- shared NFS writable group name: `homelab_nfs_shared_group_name` (default `users`)
- shared NFS writable GID: `homelab_nfs_shared_group_gid` (default `100`)

Automation on the VM can:

- verify deploy user exists
- ensure the shared group exists with the expected GID
- ensure deploy user is a member of that shared group
- print identity diagnostics (`id`, group mapping, supplementary groups)
- verify NAS-backed paths exist and are writable via write probes as the deploy user context (`become: false`)

Limits (important):

- if NAS path exists but write probes still fail, this is typically NAS-side ACL/NFS export mapping behavior (common on QNAP)
- playbooks fail clearly and report path + effective VM identity, but they do not attempt to force-fix NAS ACLs from the NFS client side
- if path owner/group appears as `65534:65534` (`nobody/nogroup`), your NAS export is likely applying anonymous/all-squash mapping; adjust QNAP NFS export mapping and RW ACLs for the intended UID/GID

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

### One-command global run (bootstrap + all stacks)

```bash
ansible-playbook playbooks/deploy-all.yml
```

This runs provisioning, disk prep, NFS mount, identity prep, NAS structure checks, NAS app-path preparation (create + permission alignment attempts), and then deploys whoami + memos + journiv in sequence.

If `apt/dpkg` is temporarily locked on the VM, the NFS mount step now waits for the package lock timeout instead of failing immediately.

### Step-by-step run

1. Provision VM (create-only, includes immediate Proxmox root-disk resize to `vm_root_disk_size_gb` when needed)

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

5. Prepare VM identity/group mapping for NFS-backed writes

```bash
ansible-playbook playbooks/prepare-identity-and-permissions.yml
```

6. Prepare NAS app paths (create missing directories + verify writability)

```bash
ansible-playbook playbooks/prepare-app-nas-paths.yml
```

7. Deploy smoke-test stack

```bash
ansible-playbook playbooks/deploy.yml
curl -i http://192.168.178.210:8080
```

8. Deploy app stacks one-by-one

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

`deploy-journiv.yml` prepares VM identity/group mapping, then validates NAS content/backup paths with numeric ownership diagnostics and deploy-user write probes before deployment.

`deploy-journiv.yml` healthcheck accepts common success/redirect codes (200/301/302/307/308) because Journiv root may redirect before the app is fully warm.


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
