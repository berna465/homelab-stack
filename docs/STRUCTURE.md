# Struttura homelab-stack

- config/
  - homelab.env           -> configurazione ambiente (vmid, template, bridge, ecc.)
- secrets/
  - .gitignore            -> ignora tutti i file di secrets
- scripts/
  - proxmox/
    - stack.sh            -> orchestratore principale da eseguire sul nodo Proxmox
  - docker/
    - infra-core/
      - docker-compose.yml
      - .env.example
    - apps-core/
      - docker-compose.yml
      - .env.example

Idea:
- Sul nodo Proxmox si clona questo repo.
- Si modifica config/homelab.env con i propri parametri.
- Si aggiungono i file .env reali sotto secrets/ (NON in git).
- Si esegue scripts/proxmox/stack.sh per creare/aggiornare le VM
  e poi (in futuro) per fare il provisioning automatico dei container.
