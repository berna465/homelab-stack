# Agent guidance for this repository

- Keep tasks small and incremental.
- Prefer one application stack at a time.
- Do not refactor unrelated files.
- Keep provisioning create-only unless explicitly requested otherwise.

## Storage architecture rules

- Primary VM: `homelab-core` (VMID `210`).
- VM local data disk mounted at `/data` is for technical persistence only.
- NAS mounted via NFS under `/mnt/nas` is the default location for persistent user content.
- Do not use VM root filesystem as default persistent storage.

### Use `/data` for

- `/data/stacks` (compose stacks/runtime dirs)
- `/data/db` (PostgreSQL/MariaDB)
- `/data/cache` (Redis/Valkey)
- `/data/runtime` (local app runtime state)
- `/data/backups-local` (local technical backups)

### Use `/mnt/nas` for

- uploads/media/documents/photos
- app content and shared files
- exported files and backups

### Hard constraints

- Do **not** place PostgreSQL/MariaDB data on NFS.
- Do **not** place Redis/Valkey data on NFS.
- Preserve `become: true` in deploy playbooks where privileged filesystem paths are used.
- Root disk must be sized for container image pulls and runtime overhead.

---

Project: homelab-stack

## Important context update

The current repository and automation are working as a v1 prototype, but the storage strategy has evolved.

We are now adopting a cleaner and more intentional architecture.

It is acceptable to rebuild the VM from scratch.

This means:

* you do NOT need to preserve the current VM state
* you do NOT need to patch every current path in place
* you MAY refactor the repository to align with the new storage model
* you should prefer a clean rebuild over incremental hacks

## New target architecture

We keep a single VM for now:

* VM name: `homelab-core`
* VMID: `210`
* Proxmox host: `proxmox.home.bernardolab.it`
* VM IP: `192.168.178.210`

The VM is the compute/runtime layer.

The NAS is the default storage layer for persistent content.

The VM local disk is only for technical persistence and runtime-critical data.

## Core storage strategy

### Rule of thumb

* Default storage location for persistent app content: NAS via NFS
* Local VM storage only for explicit technical exceptions

### Local VM storage (`/data`)

Use `/data` for:

* databases
* redis / valkey
* cache
* runtime temp data
* local app state that should stay on fast local disk
* compose stacks and app runtime directories if needed

Suggested structure:

/data/
stacks/
db/
cache/
runtime/
backups-local/

### NAS mount (`/mnt/nas`)

Mount NFS shares from the NAS under:

/mnt/nas/
media/
documents/
photos/
apps/
backups/
shared/

Use NAS storage for:

* uploads
* media libraries
* user content
* exported files
* documents
* large persistent content
* shared content across services
* backup targets

## Important design principle

The VM is the engine.
The NAS is the memory.

This means:

* PostgreSQL stays local on `/data/db/...`
* MariaDB stays local on `/data/db/...`
* Redis / Valkey stay local on `/data/cache/...`
* heavy user content goes to `/mnt/nas/...`
* backups go to `/mnt/nas/backups/...`

## What NOT to do

* Do not put local databases on NFS
* Do not put Redis / Valkey on NFS
* Do not keep heavy app data on the root filesystem
* Do not treat the VM root filesystem as the default storage location
* Do not preserve old `/opt/...` assumptions if they conflict with the new model

## Rebuild strategy

Because the VM can be recreated, the repository should now reflect the new clean design.

Please refactor the Ansible repository so that a fresh rebuild of `homelab-core` follows this strategy from the start.

You do NOT need to preserve compatibility with old stack paths unless it is trivial.

## New repository direction

Keep the repository simple, but align it to the new storage strategy.

Expected repository concerns:

* provisioning VM
* attaching and preparing local data disk
* mounting NFS shares from NAS
* deploying app stacks with the new path model

A reasonable structure may remain similar to:

ansible.cfg
inventory/
group_vars/
playbooks/
files/
README.md
AGENTS.md

But stack deployment paths and examples should reflect the new model.

## Required refactor goals

Please adapt the repository to the new storage architecture.

### 1. VM provisioning

Keep:

* single VM provisioning
* Proxmox via Ansible
* create-only provisioning behavior

### 2. Local data disk

Keep and align:

* second disk attachment
* filesystem creation
* mount at `/data`

### 3. NAS / NFS mounting

Add Ansible automation to:

* mount NAS shares persistently under `/mnt/nas/...`
* keep mount definitions explicit and readable
* make NFS mounts part of the standard VM setup

### 4. Application path model

Refactor app deployment examples to use the new conventions:

#### Local paths

* `/data/db/...`
* `/data/cache/...`
* `/data/runtime/...`
* `/data/stacks/...`

#### NAS-backed paths

* `/mnt/nas/apps/...`
* `/mnt/nas/media/...`
* `/mnt/nas/documents/...`
* `/mnt/nas/backups/...`

### 5. App examples

Adapt existing example stacks to the new strategy.

Use these principles:

#### whoami

* remains a smoke test
* minimal local footprint

#### memos

* local lightweight state if needed
* backups/export on NAS if applicable

#### journiv

* postgres local
* valkey local
* app runtime local
* media/logical content on NAS where appropriate

Future examples should follow the same strategy.

## Required tasks for Codex

Please update the repository to support a fresh clean build using the new model.

Specifically:

1. review and refactor variables and playbooks to reflect `/data` and `/mnt/nas`
2. ensure local data disk preparation remains clean and re-runnable
3. add NFS mount playbooks and variables
4. update app deployment playbooks to use the new path conventions
5. update README with the new architecture and execution order
6. update AGENTS.md to encode the new storage rules

## NFS requirements

Add support for mounting NAS shares under `/mnt/nas`.

Please keep the implementation explicit and configurable.

Suggested variables:

* NAS hostname or IP
* NFS export paths
* local mountpoints

Example conceptual mapping:

* NAS export for apps content -> `/mnt/nas/apps`
* NAS export for media -> `/mnt/nas/media`
* NAS export for backups -> `/mnt/nas/backups`

Do not hardcode user-specific secrets.
Use placeholders where exact NAS details are not known.

## Execution order in README

The README should clearly describe a clean rebuild flow, for example:

1. provision VM
2. attach local data disk
3. prepare and mount local data disk at `/data`
4. mount NAS NFS shares at `/mnt/nas/...`
5. deploy smoke test stack
6. deploy real app stacks one by one

## Implementation style

* Keep everything simple
* Prefer explicit over generic
* Avoid overengineering
* Avoid giant abstractions
* Keep playbooks readable
* Keep one app stack at a time
* Preserve `become: true` where needed
* Do not redesign the whole system beyond what is needed for the new storage strategy

## Important repository principles

* one VM only for now
* one app stack at a time
* separate deploy playbook per app
* no reverse proxy yet unless explicitly requested
* no auth layer yet unless explicitly requested
* no Dokploy
* no CasaOS
* no premature multi-VM architecture

## Done criteria

The refactor is complete when:

1. the repository supports rebuilding `homelab-core` cleanly
2. `/data` is the standard local technical persistence layer
3. NFS mounts under `/mnt/nas/...` are part of the setup
4. app deployment examples follow the new storage model
5. README and AGENTS.md explain the new strategy clearly
6. the repository is simpler and cleaner than the current incremental prototype, not more complex

## Summary

We are not trying to preserve the current VM as-is.

We are using what we learned to establish a cleaner architecture:

* local VM disk for technical persistence
* NAS via NFS as default persistent content layer
* simple Ansible-driven rebuild
* one app at a time
* clean, explicit, re-runnable repository
