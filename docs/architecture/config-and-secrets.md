# Config and secrets model

## Variable hierarchy

- `ansible/inventories/production/group_vars/all.yml`: global conventions only.
- `ansible/inventories/production/group_vars/homelab_core.yml`: node-specific values and stack toggles/overrides.

## Runtime configuration pattern

- Repo-safe defaults: `apps/stacks/<app>/.env.example`
- Optional NAS override env: `/mnt/nas/data/homelab-config/app-env/<app>.env`
- Optional NAS secrets files: `/mnt/nas/data/homelab-config/secrets/<app>/...`
- Runtime file materialized by Ansible: `/data/stacks/<app>/.env`

## Secrets strategy

- Keep secrets out of git.
- Prefer `*_FILE`/Docker secrets where natively supported.
- Keep `.env` fallback for stacks that do not support file-based secrets yet.
