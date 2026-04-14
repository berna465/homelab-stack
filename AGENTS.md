# Agent guidance for this repository

## Core operating style

- Keep tasks small and incremental.
- Prefer one application stack at a time.
- Do not refactor unrelated files.
- Keep provisioning create-only unless explicitly requested otherwise.
- Preserve `become: true` for local filesystem tasks under `/data/...`.
- Be careful with `become: true` on NFS mounts, as root may not have write access due to NFS permissions.

## Project baseline

- Project: `homelab-stack`
- Proxmox host: `proxmox.home.bernardolab.it`
- Single VM: `homelab-core` (`VMID 210`, `192.168.178.210`)
- Clean rebuild is allowed; old path assumptions do not need to be preserved.

---

## Configuration model

The repository provides default configuration and templates.

Environment-specific configuration may live on the NAS and override repo defaults when present.

### Preferred NAS configuration root

- `/mnt/nas/data/homelab-config/`

### Possible structure

- `/mnt/nas/data/homelab-config/group_vars/`
- `/mnt/nas/data/homelab-config/secrets/`
- `/mnt/nas/data/homelab-config/app-env/`

### Rules

- Repo contains:
  - default `group_vars`
  - `.env.example` files
  - playbooks
  - compose templates

- NAS may contain:
  - real environment overrides
  - secrets and credentials
  - `.env` files used at runtime

### Behavior

- Use repo defaults when no NAS configuration is present.
- If NAS configuration exists, prefer it over repo defaults.
- Do not assume NAS configuration always exists.
- Do not duplicate full repository logic on the NAS.

### Constraints

- Do not store playbooks or repository logic on the NAS.
- Do not rely exclusively on NAS configuration for bootstrap.
- The system must remain rebuildable from the repository alone.

---

## Storage source of truth

### Local VM storage (`/data`) = technical persistence only

Use:

- `/data/stacks/...`
- `/data/db/...`
- `/data/cache/...`
- `/data/runtime/...`
- `/data/backups-local/...`

### NAS storage (`/mnt/nas/...`) = persistent content layer

Mounted shares:

- `/mnt/nas/data` from `/DATA`
- `/mnt/nas/media` from `/Media`
- `/mnt/nas/backups` from `/Backups`
- `/mnt/nas/clouds` from `/Clouds`

### Writable application content

- `/mnt/nas/data/apps/<app>/...`

### Backups

- `/mnt/nas/backups/<app>/...`

### Media libraries

- `/mnt/nas/media/...` is for:
  - movies
  - music
  - TV
  - photo/media collections

Do not treat `/mnt/nas/media` as generic writable app storage.

---

## Hard constraints

- Do **not** put PostgreSQL/MariaDB data on NFS.
- Do **not** put Redis/Valkey data on NFS.
- Do **not** use `/opt/...` as the app storage default in the new model.
- Do **not** put heavy persistent app data on VM root filesystem.
- Do **not** create generic app directories directly under `/mnt/nas/media`.
- If an NFS-backed required app path is missing or not writable, fail clearly.

---

## Architecture boundaries

- The runtime platform must be Linux-native; Proxmox is only one possible infrastructure substrate.
- Provisioning is not the same as foundations, and foundations are not the same as application deployment.
- `infra/` contains environment-specific provisioning only.
- `platform/foundations/` contains Linux-native shared runtime prerequisites.
- `platform/services/` contains shared platform capabilities, not application stacks.
- `apps/` contains application stacks and deploy logic.
- `legacy/` is isolated and must not receive new primary logic.
- One app stack at a time.
- Separate deploy playbook per app.
- No reverse proxy/auth layer unless explicitly requested.
- No Dokploy/CasaOS integration.
- No premature multi-VM redesign.

---

## Storage rules

- Use `/data/...` for local technical persistence only:
  - databases
  - cache
  - runtime
  - stack directories

- Use `/mnt/nas/data/apps/...` for writable persistent application content

- Use `/mnt/nas/backups/...` for backups

- Use `/mnt/nas/media/...` only for media libraries:
  - movies
  - music
  - TV
  - photo/media collections

- Do not create application content directly under `/mnt/nas/media`

- Do not place local databases or Redis/Valkey on NFS
