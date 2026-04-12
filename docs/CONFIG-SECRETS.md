# Strategia config / env / secrets

## Obiettivi

- niente password hardcoded nei compose
- `.env.example` versionati ma non sensibili
- supporto base per secrets centralizzati su NAS

## Modello consigliato

### 1) Repo (`files/homelab-core/<app>/.env.example`)

Contiene:
- variabili non sensibili
- placeholder (`CHANGE_ME`) per segreti
- path standard locali/NAS

### 2) NAS app-env (`/mnt/nas/data/homelab-config/app-env/<app>.env`)

Contiene:
- override runtime non sensibili o semi-sensibili
- valori specifici ambiente

### 3) NAS secrets (`/mnt/nas/data/homelab-config/secrets/...`)

Contiene:
- secret files (una password per file)
- eventuali override yaml ansible secret-only

## Base docker secrets (proposta concreta)

Per ogni app introdurre gradualmente:

- directory: `/mnt/nas/data/homelab-config/secrets/<app>/`
- file: `db_password`, `redis_password`, ecc.
- in compose: montare secret file come `secrets:` o bind readonly
- in env: usare variabili `*_FILE` dove supportate dall'immagine

### Fallback quando `*_FILE` non è supportato

- mantenere secret in file su NAS
- renderizzare `.env` runtime con Ansible leggendo secret file (senza committare valore in git)
- passare variabile classica solo a runtime (`DB_PASSWORD`) ma con origine da file secret

Questo permette migrazione progressiva senza rompere stack esistenti (incluso Immich).
