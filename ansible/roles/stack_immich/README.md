# role: stack_immich

First active role-based stack blueprint.

## Responsibilities

- ensure local runtime directories for Immich
- verify required NAS paths are writable
- sync `stacks/immich/compose.yaml`
- generate runtime `.env` from repo baseline + optional NAS override
- run `docker compose up -d`
- execute post-deploy healthcheck

## Rollback/compatibility

`playbooks/deploy-immich.yml` supports fallback to legacy task flow with:

```yaml
immich_use_role: false
```
