# Legacy

This directory contains deprecated or transitional assets kept temporarily for migration safety.

Legacy content is not canonical and must not receive new primary logic.

## Canonical paths

- Infrastructure provisioning: `infra/.../ansible/playbooks/`
- Platform foundations: `platform/foundations/ansible/playbooks/`
- Application stacks: `apps/stacks/`
- Active application deploys: `apps/deploy/ansible/playbooks/`
- Platform services: `platform/services/ansible/playbooks/`

## Deprecated content

Moved legacy assets live under `legacy/deprecated/`, including:

- old shell-based bootstrap and deploy flows
- duplicate compose/env assets
- legacy Proxmox helper scripts
- obsolete docs and configuration files
