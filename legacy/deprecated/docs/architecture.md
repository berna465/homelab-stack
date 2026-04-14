# Architettura Homelab

- Proxmox:
  - vmbr0: LAN (192.168.178.0/24)
  - vmbr2: rete interna (10.10.0.0/24)
  - vmbr3: mgmt (172.16.0.0/24)

- VM infra-core:
  - mgmt: 172.16.0.2 (vmbr3)
  - internal: 10.10.0.2 (vmbr2)

- VM apps-core:
  - internal: 10.10.0.3 (vmbr2)

Stack docker:
- infra-core: proxy, SSO, DNS interno, monitoring, ecc.
- apps-core: wiki, appunti, tool vari.
