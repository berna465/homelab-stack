# role: stack_immich

Compatibility shim for the canonical Immich role now owned under `apps/deploy/ansible/roles/stack_immich`.

`playbooks/deploy-immich.yml` still supports fallback to the legacy task flow with:

```yaml
immich_use_role: false
```
