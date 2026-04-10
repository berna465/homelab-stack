# homelab-stack (Ansible v1)

Minimal Ansible infrastructure-as-code for one Proxmox VM (`homelab-core`) with simple, app-by-app Docker Compose deployments.

Current validated flows:

1. Provision VM with `qm` commands via Ansible
2. SSH into the VM
3. Deploy independent Docker Compose stacks
4. Verify HTTP health checks
5. Attach and prepare a dedicated data disk for persistent app data

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
│   ├── deploy.yml                 # whoami smoke-test stack
│   ├── deploy-memos.yml           # memos app stack
│   ├── deploy-journiv.yml         # journiv app stack
│   ├── attach-data-disk.yml       # attach dedicated disk in Proxmox
│   └── prepare-data-disk.yml      # format, mount, and prepare /data
└── files/
    └── homelab-core/
        ├── docker-compose.yml     # whoami smoke-test stack
        ├── .env.example           # whoami example env
        ├── memos/
        │   ├── docker-compose.yml
        │   └── .env.example
        └── journiv/
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

### 3) Verify SSH to homelab-core

```bash
ansible homelab_core -m command -a "hostname"
```

### 4) Deploy whoami smoke-test stack (baseline)

```bash
ansible-playbook playbooks/deploy.yml
```

Quick check:

```bash
curl -i http://192.168.178.210:8080
```

### 5) Deploy memos stack

```bash
ansible-playbook playbooks/deploy-memos.yml
```

What this playbook does:

- creates `/opt/memos` and `/opt/memos/data`
- copies `files/homelab-core/memos/docker-compose.yml`
- copies `files/homelab-core/memos/.env.example` to `/opt/memos/.env`
- runs `docker compose up -d`
- checks `http://127.0.0.1:5230/api/v1/status` from the VM

### 6) Test memos externally

```bash
curl -i http://192.168.178.210:5230/api/v1/status
```

If deployment is healthy, the endpoint returns `HTTP/1.1 200`.

Open in browser:

- `http://192.168.178.210:5230`

### 7) Deploy journiv stack

```bash
ansible-playbook playbooks/deploy-journiv.yml
```

What this playbook does:

- creates `/opt/journiv` and `/opt/journiv/data` (plus app/postgres/valkey subdirectories)
- copies `files/homelab-core/journiv/docker-compose.yml`
- copies `files/homelab-core/journiv/.env.example` to `/opt/journiv/.env`
- runs `docker compose up -d`
- checks `http://127.0.0.1:8010/` from the VM

### 8) Test journiv externally

```bash
curl -i http://192.168.178.210:8010/
```

Open in browser:

- `http://192.168.178.210:8010`


### 9) Attach dedicated data disk on Proxmox

```bash
ansible-playbook playbooks/attach-data-disk.yml
```

What this playbook does:

- reads VM `210` configuration from Proxmox
- checks whether slot `scsi1` is already configured
- attaches a new disk (default `local-lvm:40`) only when missing

### 10) Prepare and mount data disk inside homelab-core

```bash
ansible-playbook playbooks/prepare-data-disk.yml
```

What this playbook does:

- detects the secondary disk (or uses `vm_data_disk_device` when set)
- creates an `ext4` filesystem when the disk is not formatted yet
- mounts the disk persistently at `/data` using UUID in `/etc/fstab`
- creates standard persistence directories under `/data`:
  - `/data/apps`
  - `/data/db`
  - `/data/memos`
  - `/data/journiv`
  - `/data/bookstack`

### 11) Verify mounted data disk

```bash
ansible homelab_core -b -m command -a "findmnt /data"
ansible homelab_core -b -m command -a "df -h /data"
ansible homelab_core -b -m command -a "ls -la /data"
```

## Notes

- Keep stacks independent and deploy one app at a time.
- No reverse proxy/authelia/cloudflared in v1.
- `playbooks/deploy.yml` (whoami) remains as the known-good baseline.
