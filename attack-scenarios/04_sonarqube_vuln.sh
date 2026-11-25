#!/bin/bash
# ============================================================
# Scénario 6: SonarQube Quality Gate - Code vulnérable
# Objectif: Montrer que le pipeline CI/CD bloque sur code vulnérable
# ============================================================

echo "[*] Scénario 6: SonarQube Quality Gate"
echo ""

# Créer un fichier Python avec vulnérabilités intentionnelles
mkdir -p /tmp/vuln-test
cat > /tmp/vuln-test/app_vuln.py <<'PYEOF'
import os
import subprocess
import hashlib

# VULNÉRABILITÉ 1: SQL Injection (CWE-89)
def get_user(user_input):
    query = "SELECT * FROM users WHERE name = '" + user_input + "'"  # noqa
    return query

# VULNÉRABILITÉ 2: Command Injection (CWE-78)
def run_command(user_cmd):
    os.system(user_cmd)  # Dangereux!
    subprocess.call(user_cmd, shell=True)  # Encore plus dangereux!

# VULNÉRABILITÉ 3: Mot de passe hardcodé (CWE-798)
PASSWORD = "admin123"  # noqa: S105
API_KEY = "sk-1234567890abcdef"  # noqa: S105

# VULNÉRABILITÉ 4: Hash MD5 faible (CWE-327)
def weak_hash(data):
    return hashlib.md5(data.encode()).hexdigest()

# VULNÉRABILITÉ 5: Path traversal (CWE-22)
def read_file(filename):
    with open("/var/data/" + filename, 'r') as f:
        return f.read()
PYEOF

echo "[+] Fichier vulnérable créé: /tmp/vuln-test/app_vuln.py"
echo ""
echo "[*] Pour tester avec SonarQube:"
echo "    1. Pousse ce fichier dans ton repo GitHub"
echo "    2. Le pipeline CI/CD va lancer SonarQube"
echo "    3. SonarQube détecte les 5 vulnérabilités"
echo "    4. Quality Gate = FAILED → pipeline bloqué"
echo "    5. L'image n'est PAS envoyée à Nexus"
echo ""
echo "[+] Vulnérabilités dans le fichier:"
echo "    - SQL Injection (CWE-89)"
echo "    - Command Injection (CWE-78)"
echo "    - Hardcoded Password (CWE-798)"
echo "    - Weak Hash MD5 (CWE-327)"
echo "    - Path Traversal (CWE-22)"

# Scan local avec Trivy si disponible
if command -v trivy &>/dev/null; then
    echo ""
    echo "[*] Scan Trivy local..."
    trivy fs /tmp/vuln-test/ --severity HIGH,CRITICAL 2>/dev/null || true
fi

echo ""
echo "[+] Scénario SonarQube terminé ✓"
