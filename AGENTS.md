# Agent guidance for this repository

## Core operating style

- Keep tasks small and incremental.
- Prefer one application stack at a time.
- Do not refactor unrelated files.
- Keep provisioning create-only unless explicitly requested otherwise.
- Preserve `become: true` in deploy playbooks where privileged filesystem paths are used.

## Project baseline

- Project: `homelab-stack`
- Proxmox host: `proxmox.home.bernardolab.it`
- Single VM: `homelab-core` (`VMID 210`, `192.168.178.210`)
- Clean rebuild is allowed; old path assumptions do not need to be preserved.

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

Writable app content should go under:

- `/mnt/nas/data/apps/<app>/...`

Backups should go under:

- `/mnt/nas/backups/<app>/...`

`/mnt/nas/media` is for media libraries (movies/music/tv/photos) and must not be treated as generic app-write storage.

## Hard constraints

- Do **not** put PostgreSQL/MariaDB data on NFS.
- Do **not** put Redis/Valkey data on NFS.
- Do **not** use `/opt/...` as the app storage default in the new model.
- Do **not** put heavy persistent app data on VM root filesystem.
- Do **not** create generic app directories directly under `/mnt/nas/media`.
- If an NFS-backed required app path is missing or not writable, fail clearly.

## Architecture boundaries

- One VM only for now.
- One app stack at a time.
- Separate deploy playbook per app.
- No reverse proxy/auth layer unless explicitly requested.
- No Dokploy/CasaOS integration.
- No premature multi-VM redesign.

## Storage rules

* Use `/data/...` for local technical persistence only:

  * databases
  * cache
  * runtime
  * stack directories

* Use `/mnt/nas/data/apps/...` for writable persistent application content

* Use `/mnt/nas/backups/...` for backups

* Use `/mnt/nas/media/...` only for media libraries

  * movies
  * music
  * TV
  * photo/media collections

* Do not create application content directly under `/mnt/nas/media`

* Do not place local databases or Redis/Valkey on NFS

