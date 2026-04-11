---
name: homelab-rebuild
description: Refactor and extend the homelab-stack repository for a rebuildable single-VM homelab using Ansible, Proxmox, local /data storage for technical persistence, and NAS NFS mounts for persistent app content.
---

# Purpose

Use this skill when working on the `homelab-stack` repository.

This repository manages a personal homelab with:

- Proxmox for VM provisioning
- Ansible for automation
- Docker Compose for app deployment
- one VM only for now: `homelab-core`

The goal is to keep the environment rebuildable, explicit, and simple.

# Core architecture

## VM role

The VM is the compute/runtime layer.

Use local VM storage only for technical persistence:

- `/data/stacks/...`
- `/data/db/...`
- `/data/cache/...`
- `/data/runtime/...`
- `/data/backups-local/...`

## NAS role

The NAS is the persistent content layer.

Mounted NFS paths:

- `/mnt/nas/data`
- `/mnt/nas/media`
- `/mnt/nas/backups`
- `/mnt/nas/clouds`

Use them like this:

- `/mnt/nas/data/apps/...` -> writable app content
- `/mnt/nas/backups/...` -> backups
- `/mnt/nas/media/...` -> media libraries only

## Important storage rules

- Do NOT put PostgreSQL or MariaDB on NFS
- Do NOT put Redis or Valkey on NFS
- Do NOT use VM root filesystem for heavy app data
- Do NOT create generic app content under `/mnt/nas/media`
- Treat `/mnt/nas/media` as media-library storage only
- Use `/mnt/nas/data/apps/<app>` for writable app content

# Repository rules

## Keep architecture simple

- one VM only
- one app stack at a time
- one deploy playbook per app
- create-only provisioning
- separate playbooks for:
  - VM provisioning
  - data disk attachment/preparation
  - NFS mount setup
  - app deployment

## Do not introduce

- Dokploy
- CasaOS integration
- reverse proxy unless explicitly requested
- auth layer unless explicitly requested
- multi-VM architecture
- giant abstractions

# Expected path conventions

## Local paths

- `/data/stacks/<app>`
- `/data/db/<app-or-db>`
- `/data/cache/<app-or-cache>`
- `/data/runtime/<app>`

## NAS paths

- `/mnt/nas/data/apps/<app>/...`
- `/mnt/nas/backups/<app>/...`

# App deployment model

For each app:

1. ensure local directories under `/data/...`
2. verify required NAS paths under `/mnt/nas/...`
3. do not assume NAS roots are writable
4. fail clearly if a required NAS path is missing or not writable
5. keep deploy playbooks re-runnable
6. use `become: true` for local filesystem tasks
7. be careful with NFS/root-squash behavior when checking NAS writability

# Current app guidance

## whoami
- smoke test only
- minimal persistence

## memos
- lightweight app
- local minimal state acceptable
- backups/exports may go to `/mnt/nas/backups/memos`

## journiv
Use this model:

- stack dir: `/data/stacks/journiv`
- postgres: `/data/db/journiv-postgres`
- valkey: `/data/cache/journiv-valkey`
- runtime: `/data/runtime/journiv`
- app content: `/mnt/nas/data/apps/journiv`
- backups: `/mnt/nas/backups/journiv`

Do NOT use `/mnt/nas/media/journiv`.

# Configuration model

The repo should keep standard defaults.

The environment-specific state should live on the NAS when available.

Preferred model:

- repo contains:
  - default `group_vars`
  - default examples
  - playbooks
  - compose templates
  - `.env.example`

- NAS may contain:
  - real environment overrides
  - secrets
  - `.env` files
  - host-specific vars

The environment is rebuildable and can bootstrap from the repo, then adapt if NAS-hosted configuration exists.

## Preferred NAS config root

Use a path like:

- `/mnt/nas/data/homelab-config/`

Possible structure:

- `/mnt/nas/data/homelab-config/group_vars/`
- `/mnt/nas/data/homelab-config/secrets/`
- `/mnt/nas/data/homelab-config/app-env/`

# How to work

When asked to change the repo:

1. preserve current working architecture unless explicitly told to redesign
2. prefer minimal readable changes
3. do not refactor unrelated files
4. keep changes incremental
5. update `README.md` and `AGENTS.md` when architecture rules change
6. prefer explicit variables over clever autodetection when permissions or storage are involved

# Safe defaults

When in doubt:

- create local directories automatically under `/data/...`
- verify NAS paths instead of assuming they are writable
- use explicit uid/gid variables rather than fragile runtime detection
- fail with clear messages rather than silently continuing

# Definition of done

A change is good when:

- it is rebuildable
- it is readable
- it is safe to re-run
- it follows the storage model
- it does not smuggle in extra architecture
