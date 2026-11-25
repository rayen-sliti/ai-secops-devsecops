#!/bin/bash
# ============================================================
# Scénario 2: FIM - Modification de fichier sensible
# Objectif: Wazuh FIM détecte la modification de /etc/passwd
# MITRE ATT&CK: T1098 - Account Manipulation
# ============================================================
# USAGE: bash 02_fim_test.sh
# Lance directement sur la VM SOC (en tant que root)

echo "[*] Scénario 2: FIM - Fichier Integrity Monitoring"
echo "[*] MITRE: T1098 - Account Manipulation"
echo ""

# Attendre que Wazuh soit prêt
echo "[*] Vérification Wazuh agent..."
systemctl is-active --quiet wazuh-agent || {
    echo "[!] Wazuh agent non actif"
    exit 1
}

# Test 1: Modifier /etc/hosts (fichier surveillé)
echo "[*] Test 1: Modification /etc/hosts..."
echo "# Test FIM AI-SecOps - $(date)" >> /etc/hosts
sleep 2
sed -i '/Test FIM AI-SecOps/d' /etc/hosts
echo "[+] /etc/hosts modifié puis restauré"

# Test 2: Créer un fichier dans /etc (zone surveillée)
echo "[*] Test 2: Création fichier dans /etc..."
touch /etc/test-secops-fim
sleep 2
rm -f /etc/test-secops-fim
echo "[+] Fichier créé et supprimé dans /etc"

# Test 3: Modification permissions fichier sensible
echo "[*] Test 3: Changement permission /etc/shadow..."
ORIG=$(stat -c %a /etc/shadow)
chmod 644 /etc/shadow
sleep 1
chmod $ORIG /etc/shadow
echo "[+] Permission restaurée"

echo ""
echo "[+] Scénario FIM terminé"
echo "[+] Vérifie dans Wazuh Dashboard:"
echo "    - Alerte: 'Integrity checksum changed'"
echo "    - Règle: 550, 553, 554"
echo "    - MITRE: T1098"
echo "    - Module: Integrity Monitoring > Events"
