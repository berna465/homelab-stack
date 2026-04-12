# Immich app notes

## Current compatibility status

Immich deploy remains compatible with the existing flow.

- Compose source: `stacks/immich/compose.yaml`
- Baseline env: `stacks/immich/.env.example`
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

- Default path: `playbooks/deploy-immich.yml` -> `ansible/roles/stack_immich`
- Fallback path: set `immich_use_role: false` to use legacy task flow.

