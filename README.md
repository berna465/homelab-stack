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
  run-homelab.sh          # pipeline entrypoint
  provision-vms.sh        # provision VM(s) only
  bootstrap-node.sh       # bootstrap node software via HTTPS repo
  proxmox/
    build_template.sh     # builds Debian/Ubuntu cloud template
    stack.sh              # provision + deploy
    destroy_homelab.sh    # destroy created VM/template
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
# Full pipeline (recommended): build template -> provision -> bootstrap
bash scripts/run-homelab.sh all

# Only template
bash scripts/run-homelab.sh template

# Only VM provisioning
bash scripts/run-homelab.sh provision

# Only node bootstrap
bash scripts/run-homelab.sh bootstrap

# Legacy one-shot flow
bash scripts/run-homelab.sh stack

# Destroy resources
bash scripts/run-homelab.sh destroy vm
bash scripts/run-homelab.sh destroy template
bash scripts/run-homelab.sh destroy all
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
- `bootstrap-node.sh` uses HTTPS repository clone/pull (`https://github.com/berna465/homelab-stack.git`).
