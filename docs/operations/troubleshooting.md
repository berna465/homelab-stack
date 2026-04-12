# Troubleshooting

## NFS path exists but write fails

- Verify NAS export ACL/mapping for effective VM UID/GID.
- Check for `nobody/nogroup` (`65534:65534`) ownership symptoms.
- Re-run identity prep and NAS path checks.

## Missing runtime env values

- Validate `stacks/<app>/.env.example` baseline.
- Validate optional NAS override under `app-env/<app>.env`.
- Re-run app deploy playbook to regenerate `/data/stacks/<app>/.env`.

## App starts but healthcheck fails

- Confirm compose services are running on VM.
- Check configured healthcheck URL/status in `group_vars/homelab_core.yml`.
