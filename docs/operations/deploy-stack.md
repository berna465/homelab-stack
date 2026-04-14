# Deploy stacks

## Canonical commands

From repo root:

```bash
ansible-playbook ansible/playbooks/provision.yml
ansible-playbook ansible/playbooks/deploy.yml
```

Layered canonical entrypoints:

```bash
ansible-playbook infra/proxmox/ansible/playbooks/provision-host.yml
ansible-playbook infra/nas/ansible/playbooks/apply.yml
ansible-playbook platform/foundations/ansible/playbooks/apply.yml
ansible-playbook platform/services/ansible/playbooks/deploy-reverse-proxy.yml
ansible-playbook platform/services/ansible/playbooks/deploy-whoami.yml
ansible-playbook apps/deploy/ansible/playbooks/deploy-immich.yml
```

Full run:

```bash
ansible-playbook ansible/playbooks/site.yml
```

## Root disk resize (se necessario)

L'allargamento del root filesystem è separato dalla creazione VM.

```bash
ansible-playbook infra/proxmox/ansible/playbooks/resize-root-disk.yml
```
