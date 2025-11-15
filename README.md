# homelab-stack

Infrastructure-as-code per il mio homelab su Proxmox.

Obiettivi:

- Creare in modo riproducibile lo stack infrastrutturale:
  - VM `infra-core` (proxy, SSO, monitoring, DNS interno in futuro)
  - VM `apps-core` (BookStack, Memos, strumenti vari)
- Usare un template Debian 12 docker-ready su Proxmox (ID 902).
- Configurare rete e cloud-init via script in modo dichiarativo (file YAML).
- Deployare i docker-compose delle varie VM a partire dai file nel repo.
- Eseguire post-hook di verifica dopo l'installazione (healthcheck).

Struttura principale:

- `config/` — file di configurazione per ambienti (prod, dev, ecc.)
- `secrets/` — credenziali e chiavi (NON tracciate da git)
- `scripts/` — script per creare VM, configurare cloud-init, fare deploy
- `stacks/` — docker-compose per `infra-core`, `apps-core`, ecc.
- `templates/` — template cloud-init, file base, ecc.
- `docs/` — documentazione aggiuntiva

