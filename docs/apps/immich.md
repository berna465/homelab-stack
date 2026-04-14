# Immich app notes

## Current compatibility status

Immich deploy remains compatible with the existing flow.

- Compose source: `apps/stacks/immich/compose.yaml`
- Baseline env: `apps/stacks/immich/.env.example`
- Runtime env: `/data/stacks/immich/.env`

## Storage mapping

- Stack dir: `/data/stacks/immich`
- Postgres: `/data/db/immich-postgres`
- Redis: `/data/cache/immich-redis`
- Runtime/model cache: `/data/runtime/immich`
- Content: `/mnt/nas/data/apps/immich/library`
- Backups: `/mnt/nas/backups/immich`

## Secrets progression

Use `.env` fallback now; migrate selected variables to `*_FILE`/Docker secrets incrementally where support is clear and safe.
## Deploy implementation

- Canonical path: `apps/deploy/ansible/playbooks/deploy-immich.yml` -> `apps/deploy/ansible/roles/stack_immich`
- Compatibility wrapper: `playbooks/deploy-immich.yml`
- Fallback path: set `immich_use_role: false` to use legacy task flow.


## Content path policy

- Canonical host-side path: `/mnt/nas/data/apps/immich/library`
- Compatibility fallback (auto-detected by role): `/mnt/nas/data/apps/immich/upload`

Direction is `library`; keep `upload` only as temporary bridge during migration.
