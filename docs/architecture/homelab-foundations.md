# Homelab foundations

## Scope

- One Proxmox host.
- One VM (`homelab-core`) for now.
- Incremental, rebuildable automation.

## Separation of concerns

- **Provisioning**: host/compute baseline (VM, disks, NFS mounts, identity alignment).
- **Deploy**: application stacks and health checks.

Canonical entrypoints:

- `ansible/playbooks/provision.yml`
- `ansible/playbooks/deploy.yml`
- `ansible/playbooks/site.yml`

Legacy playbook aliases are preserved under `playbooks/` to avoid workflow breaks.

## Storage model

- Local VM `/data` = technical persistence only (`stacks`, `db`, `cache`, `runtime`).
- NAS `/mnt/nas/data/apps/<app>` = persistent writable app content.
- NAS `/mnt/nas/backups/<app>` = backups.
- NAS `/mnt/nas/media` = media libraries only.

Hard constraints:

- Do not place PostgreSQL/MariaDB or Redis/Valkey data on NFS.
- Do not treat `/mnt/nas/media` as generic app storage.
