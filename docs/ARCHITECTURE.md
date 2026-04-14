# Architecture

## Core Principles

- The runtime platform must be Linux-native; Proxmox is only one possible infrastructure substrate.
- Provisioning is not the same as foundations, and foundations are not the same as application deployment.

## Layers

### Infrastructure

Environment-specific substrate preparation.

Examples:

- Proxmox VM provisioning
- generic Linux host bootstrap
- NAS mount integration

Infrastructure produces a reachable Linux host with storage and network prerequisites.

### Platform Foundations

Linux-native runtime foundations shared by all deployments.

Examples:

- Docker and Compose runtime prerequisites
- identity and permission model
- runtime directory conventions
- shared Docker networks
- host-level preflight checks

Foundations must not depend on Proxmox-specific assumptions.

### Platform Services

Shared platform capabilities consumed by applications.

Examples:

- reverse proxy
- smoke tests
- future shared observability or ingress services

### Applications

Self-hosted application stacks and their deployment logic.

Applications must consume foundations cleanly and must not recreate host bootstrap logic.

### Legacy

Deprecated or transitional assets kept only for migration safety.

Legacy paths are not canonical and must not be extended.

## Repository Direction

This repository is evolving toward a Linux-first architecture where:

- a generic Linux host is the primary runtime target
- Proxmox is an optional infrastructure path
- shared runtime concerns are separated from application deployment
- legacy compatibility remains temporary and explicit
