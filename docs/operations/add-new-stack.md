# Add a new stack

1. Create `apps/stacks/<app>/compose.yaml`.
2. Add `apps/stacks/<app>/.env.example` with non-sensitive defaults only.
3. Add `apps/stacks/<app>/README.md` with runtime paths and env guidance.
4. Add a dedicated deploy playbook under `apps/deploy/ansible/playbooks/deploy-<app>.yml`.
5. Add host-specific variables in `ansible/inventories/production/group_vars/homelab_core.yml` (or inventory equivalent).
6. Add NAS path checks (`/mnt/nas/data/apps/<app>`, `/mnt/nas/backups/<app>`) before compose up.
7. Wire the playbook into `ansible/playbooks/deploy.yml` when ready.
