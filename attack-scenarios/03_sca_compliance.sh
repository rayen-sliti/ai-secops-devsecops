#!/bin/bash
# ============================================================
# Scénario 5: SCA - Compliance avant/après Ansible
# Objectif: Montrer l'amélioration du score SCA après hardening
# MITRE ATT&CK: M1028 - OS Config
# ============================================================

echo "[*] Scénario 5: SCA Compliance Test"
echo "[*] Avant hardening Ansible → Score faible"
echo "[*] Après hardening Ansible → Score amélioré"
echo ""

# ─── AVANT HARDENING: créer une mauvaise config volontaire ────
echo "[*] Création de configurations non-conformes..."

# Désactiver des paramètres sécurité
echo "0" > /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null || true
echo "1" > /proc/sys/net/ipv4/conf/all/accept_redirects 2>/dev/null || true

# Vérifier le score SCA actuel
echo "[*] Scan SCA initial..."
/var/ossec/bin/wazuh-control restart 2>/dev/null || true
sleep 5

echo ""
echo "[+] Vérifie le score SCA AVANT dans Wazuh:"
echo "    Dashboard > Security Configuration Assessment"
echo "    Note le score initial"
echo ""
read -p "Appuie sur Entrée après avoir noté le score initial..."

# ─── LANCEMENT HARDENING ANSIBLE ──────────────────────────────
echo "[*] Lancement du hardening Ansible..."
if command -v ansible-playbook &>/dev/null; then
    ansible-playbook -i localhost, \
        -c local \
        ../ansible/playbooks/site.yml \
        --limit localhost \
        --tags hardening 2>/dev/null || \
    echo "[!] Ansible non configuré - simule le hardening manuellement"
fi

# Restaurer les bonnes configs manuellement
sysctl -w net.ipv4.tcp_syncookies=1 2>/dev/null || true
sysctl -w net.ipv4.conf.all.accept_redirects=0 2>/dev/null || true

echo ""
echo "[+] Hardening appliqué!"
echo "[+] Attends 2-3 minutes puis vérifie dans Wazuh:"
echo "    Dashboard > Security Configuration Assessment"
echo "    Le score devrait avoir augmenté"
echo ""
echo "[+] Scénario SCA terminé ✓"
