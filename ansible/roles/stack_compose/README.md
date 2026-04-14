# role: stack_compose

Generic role for simple Docker Compose application stacks.

## Responsibilities

- ensure local stack directories exist
- optionally prepare deploy identity for NAS-backed writes
- verify required NAS paths are present and writable
- sync stack `compose.yaml`
- materialize runtime `.env` from repo baseline, then append optional NAS override
- optionally validate required environment variables
- run `docker compose up -d`
- execute post-deploy healthcheck

Optional healthcheck headers can be passed with `stack_healthcheck_headers`,
which is useful when validating hostname-based routing through a reverse proxy.

## Scope

This role is intended for standard stack deployments.

More complex applications with specialized merge logic or migration behavior can remain on dedicated roles until convergence is safe.
