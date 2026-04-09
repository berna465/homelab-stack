# homelab-stack (v1)

Minimal, idempotent Proxmox + Docker bootstrap for a single VM:

- VM name: `homelab-core`
- Template: Debian 12 template `902`
- Network: one bridge (`vmbr0`), one static IP, no VLANs
- Stack: one minimal Docker Compose app

## Repository layout

```text
config/
  homelab.env
secrets/
  .gitignore
  homelab-core.env        # local only, ignored by git
docker/
  homelab-core/
    docker-compose.yml
    .env.example
scripts/
  proxmox/
    stack.sh              # main entrypoint
  docker/
    deploy_stack.sh
    healthcheck.sh
```

## 1) Configure values

Edit:

- `config/homelab.env`

Create/update local secret file:

- `secrets/homelab-core.env`

## 2) Run

From the Proxmox host (or a machine that can run `qm` and SSH to the VM):

```bash
bash scripts/proxmox/stack.sh
```

## What `stack.sh` does

1. Validates required env vars and commands.
2. Checks if VM exists.
   - If missing: clones from template `902`.
   - If present: skips clone.
3. Applies VM config with `qm set` (CPU, RAM, disk, bridge, static IP cloud-init, user, SSH key).
4. Starts VM if not already running.
5. Waits until SSH is reachable.
6. Copies compose files + scripts + local secrets file to the VM.
7. Runs remote deploy (`docker compose up -d`) and healthcheck.

## Notes

Default deploy path is the VM user home (`/home/<ciuser>/homelab-core`) to avoid root permission issues.

- Scripts use `set -euo pipefail`.
- Secrets stay outside git via `secrets/.gitignore`.
- Idempotency: safe to rerun; existing VM is not recreated.
