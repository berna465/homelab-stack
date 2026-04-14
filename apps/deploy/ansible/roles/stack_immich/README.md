# role: stack_immich

Canonical application deployment role for Immich.

## Responsibilities

- ensure local runtime directories for Immich
- verify required NAS paths are writable
- sync `apps/stacks/immich/compose.yaml`
- generate runtime `.env` from repo baseline + optional NAS override
- run `docker compose up -d`
- execute post-deploy healthcheck

## Notes

Immich remains a specialized role because it has stack-specific env merge and storage fallback behavior.
