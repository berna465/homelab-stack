# Agent guidance for this repository

- Keep tasks small and incremental.
- Prefer one application stack at a time.
- Do not refactor unrelated files.
- Preserve `become: true` in deploy playbooks where `/opt/...` is used.
- Do not modify provisioning logic unless explicitly asked.
- For app stacks with persistent/local database data, prefer paths under `/data/...` (dedicated data disk) over root-disk-heavy paths.

- Root disk must be sized for container image pulls and runtime overhead.
