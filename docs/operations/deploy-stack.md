# Deploy stacks

## Canonical commands

From repo root:

```bash
ansible-playbook ansible/playbooks/provision.yml
ansible-playbook ansible/playbooks/deploy.yml
```

Full run:

```bash
ansible-playbook ansible/playbooks/site.yml
```

## Compatibility aliases

These continue to work:

- `playbooks/compute/provision-base.yml`
- `playbooks/stacks/deploy-all-apps.yml`
- `playbooks/deploy-all.yml`

## Root disk resize (se necessario)

L'allargamento del root filesystem è separato dalla creazione VM.

```bash
ansible-playbook playbooks/resize-root-disk.yml
```

