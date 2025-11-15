Questo documento descrive la configurazione NAT sul nodo Proxmox `pve-node1`
per dare accesso a Internet alle VM dei segmenti interni.

## Assunzioni

- Host: **Proxmox VE** (`pve-node1`)
- Uplink verso il Fritz!Box:
  - bridge: `vmbr0`
  - rete: `192.168.178.0/24` (LAN di casa)
- Reti interne del lab:
  - `vmbr2` → rete **internal**: `10.10.0.0/24`
  - `vmbr3` → rete **mgmt**: `172.16.0.0/24`
- Le VM (`infra-core`, `apps-core`, ecc.) hanno:
  - IP `10.10.0.x/24` su `vmbr2`
  - IP `172.16.0.x/24` su `vmbr3` (solo dove serve mgmt)

## 1. Abilitare IP forwarding

Creare un file di configurazione sysctl dedicato:

```bash
cat >/etc/sysctl.d/99-ipforward.conf <<'EOT'
net.ipv4.ip_forward=1
EOT

sysctl --system

sysctl net.ipv4.ip_forward
# deve restituire: net.ipv4.ip_forward = 1

## 2. Installare iptables-persistent (se non presente)
apt-get update
apt-get install -y iptables-persistent


Se chiede di salvare le regole correnti, puoi rispondere Yes (o No e poi le salvi dopo).

## 3. Regole NAT iptables

L’obiettivo è fare MASQUERADE delle reti interne (10.10.0.0/24 e 172.16.0.0/24)
in uscita sull’interfaccia/bridge verso il Fritz!Box (vmbr0).

3.1 Regole di base
# NAT per la rete internal (vmbr2: 10.10.0.0/24)
iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o vmbr0 -j MASQUERADE

# NAT per la rete mgmt (vmbr3: 172.16.0.0/24)
iptables -t nat -A POSTROUTING -s 172.16.0.0/24 -o vmbr0 -j MASQUERADE

3.2 Regole di FORWARD (statoful)
# Tra vmbr2 (internal) e vmbr0 (uplink)
iptables -A FORWARD -i vmbr0 -o vmbr2 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i vmbr2 -o vmbr0 -j ACCEPT

# Tra vmbr3 (mgmt) e vmbr0 (uplink)
iptables -A FORWARD -i vmbr0 -o vmbr3 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i vmbr3 -o vmbr0 -j ACCEPT


Nota: le regole sopra sono molto aperte, ma accettabili per un lab casalingo.
Se in futuro abiliti pve-firewall, andrà rivista l’integrazione.

## 4. Salvare le regole (persistenza)

Salva la configurazione corrente di iptables:

iptables-save > /etc/iptables/rules.v4


Per ricaricarle manualmente:

iptables-restore < /etc/iptables/rules.v4


iptables-persistent si occuperà di ripristinarle in automatico al boot.

## 5. Test dalla VM

Dalla VM (es. infra-core o apps-core):

ping -c 3 8.8.8.8          # test con IP
ping -c 3 debian.org       # test con DNS
apt-get update             # verifica che esca davvero


Se:

il ping verso 8.8.8.8 funziona

ma il ping verso debian.org no

allora il problema è DNS sulla VM (controllare /etc/resolv.conf o la config cloud-init).

Se nessuno dei due funziona:

verificare IP / gateway nelle VM

verificare le regole iptables -t nat -L -n -v e iptables -L -n -v

verificare net.ipv4.ip_forward=1
