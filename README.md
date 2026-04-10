# homelab-stack (Ansible v1)

Minimal Ansible infrastructure-as-code for one Proxmox VM (`homelab-core`) and one Docker Compose service (`traefik/whoami`).

This repository intentionally automates only what is already validated manually:

1. Provision VM with `qm` commands via Ansible
2. SSH into the VM
3. Deploy one Docker Compose stack
4. Verify HTTP health

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
│   └── deploy.yml
└── files/
    └── homelab-core/
        ├── docker-compose.yml
        └── .env.example
```

## Environment details

- Proxmox host: `proxmox.home.bernardolab.it`
- Template VMID: `902`
- Target VM:
  - VMID: `210`
  - Name: `homelab-core`
  - IP: `192.168.178.210/24`
  - Gateway: `192.168.178.1`
  - Cloud-init user: `debian`

## Prerequisites

- Ansible installed on your control machine
- SSH access to Proxmox as `root`
- SSH public key available locally (default lookup: `~/.ssh/id_rsa.pub`)
- Template VM `902` already present on Proxmox with cloud-init enabled

## Inventory model

- Group `proxmox`:
  - host `proxmox.home.bernardolab.it`
- Group `homelab_core`:
  - host `192.168.178.210`

## Configuration

Defaults live in `group_vars/all.yml` and `group_vars/homelab_core.yml`.

Before running, verify/update:

- `vm_ssh_public_key` in `group_vars/all.yml`
- any CPU/memory values if you want different sizing

## Usage

Run commands from repository root.

### 1) Verify access to Proxmox

```bash
ansible proxmox -m command -a "hostname"
```

### 2) Provision VM (create or validate)

```bash
ansible-playbook playbooks/provision.yml
```

Behavior:
- checks if VM `210` exists
- clones from template `902` if missing
- applies CPU/memory/network/cloud-init/SSH key config
- starts VM
- waits for SSH on `192.168.178.210:22`

### 3) Verify SSH to homelab-core

```bash
ansible homelab_core -m command -a "hostname"
```

### 4) Deploy Docker service

```bash
ansible-playbook playbooks/deploy.yml
```

Behavior:
- creates `/opt/homelab-core`
- copies `docker-compose.yml`
- runs `docker compose up -d`
- verifies `http://127.0.0.1:8080` returns HTTP 200

### 5) External service check

```bash
curl -i http://192.168.178.210:8080
```

Expected result: HTTP 200 response from `traefik/whoami`.
