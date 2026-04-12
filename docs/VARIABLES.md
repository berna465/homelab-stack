# Gerarchia variabili Ansible

## Regola adottata

- `group_vars/all.yml` = variabili globali/convenzioni cross-host.
- `group_vars/homelab_core.yml` = dettagli specifici del nodo/gruppo `homelab_core`.

## Cosa sta in `all.yml`

- convenzioni storage locali (`/data/...`)
- convenzioni NFS/NAS (`/mnt/nas/...`)
- identity model VM/NFS (utente deploy, gruppo condiviso)
- convenzioni override da NAS (`homelab-config/...`)
- baseline infrastrutturale comune (es. sizing dischi)

## Cosa sta in `homelab_core.yml`

- parametri istanza VM (`vm_id`, `vm_name`, `vm_ipconfig0`, risorse)
- path e healthcheck stack app
- env override file per app (`<app>_nas_env_file`)

## Decisione su consolidamento

**Non consolidato in un solo file**.

Motivazione:
- `all.yml` mantiene convenzioni riusabili e leggibili anche con future VM.
- `homelab_core.yml` resta il punto unico per override/specificità del nodo.
- Si riduce accoppiamento tra policy globale e configurazione host.

Inoltre è stata ridotta la duplicazione: i path NAS in `homelab_core.yml` derivano da `nas_nfs_mount_root` globale.
