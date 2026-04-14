# infra-edge stack

Shared ingress platform service based on Traefik.

## Responsibilities

- provide a shared Docker network for HTTP-facing services
- terminate HTTP ingress on ports 80 and 443
- discover routable containers through Docker labels
- expose the Traefik dashboard only on localhost by default

## Runtime config

- repo baseline: `platform/services/stacks/infra-edge/.env.example`
- optional NAS override: `{{ nas_config_app_env_dir }}/infra-edge.env`
- runtime env materialized by Ansible: `/data/stacks/infra-edge/.env`

## Notes

- This stack prepares the ingress layer without forcing application stacks to adopt proxy labels immediately.
- Application integration can be rolled out incrementally per stack.
