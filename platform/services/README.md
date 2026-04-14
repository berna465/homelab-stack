# Platform Services

This directory will contain shared platform capabilities consumed by applications.

Examples:

- reverse proxy
- smoke-test services
- shared observability components

Application stacks do not belong here unless they are truly platform-wide shared services.

Current canonical service stacks:

- `platform/services/stacks/infra-edge/`
- `platform/services/stacks/whoami/`
