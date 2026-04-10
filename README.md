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
    build_template.sh     # builds Debian/Ubuntu cloud template
    stack.sh              # main entrypoint
  docker/
    deploy_stack.sh
    healthcheck.sh
```


## Build hardened template (Debian/Ubuntu)

Create or refresh Proxmox template VM (`TEMPLATE_ID`, default `902`) from official cloud images:

```bash
# Debian 12 template
bash scripts/proxmox/build_template.sh

# Ubuntu 24.04 template
TEMPLATE_OS=ubuntu TEMPLATE_ID=903 TEMPLATE_NAME=ubuntu24-cloud-template \
  bash scripts/proxmox/build_template.sh
```

To recreate an existing template VMID, set `FORCE_RECREATE=1`.

If a template keeps failing at first boot, recreate it from scratch:

```bash
rm -f /var/lib/vz/template/qemu/debian-12-genericcloud-amd64.qcow2
FORCE_RECREATE=1 TEMPLATE_OS=debian TEMPLATE_ID=902 bash scripts/proxmox/build_template.sh
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
- For Ubuntu templates, set `VM_CIUSER=ubuntu` (or let `stack.sh` fallback to `ubuntu` automatically if SSH key login for the configured user fails).
- Remote deploy now auto-detects whether to run `docker compose` directly or through passwordless `sudo` when socket permissions require it.
