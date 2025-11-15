# Test di Sicurezza Autorizzato

Questo script è stato creato per eseguire un test di sicurezza autorizzato dal CISO.

## Prerequisiti
Per eseguire questo test, è necessario installare:

1. Python 3.11 o superiore
2. Il pacchetto python3-venv
3. Il modulo requests di Python

## Istruzioni per l'installazione

```bash
# Installare i prerequisiti
sudo apt update
sudo apt install -y python3-full python3-venv

# Creare un ambiente virtuale
python3 -m venv security_test_env

# Attivare l'ambiente virtuale
source security_test_env/bin/activate

# Installare le dipendenze
pip install requests

# Eseguire il test
python security_test.py
```

## Note importanti
- Assicurarsi di avere l'autorizzazione formale prima di eseguire questo test
- Documentare l'esecuzione del test e i risultati
- Informare il team operativo prima dell'esecuzione
- Eseguire il test in orari di basso traffico

## Documentazione
Conservare in questo repository:
- L'autorizzazione formale del CISO
- I risultati del test
- Le raccomandazioni di sicurezza basate sui risultati
# homelab-stack
# homelab-stack
