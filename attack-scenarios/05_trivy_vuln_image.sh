#!/bin/bash
# ============================================================
# Scénario 7: Trivy - Image Docker vulnérable rejetée
# Objectif: Montrer que Trivy bloque une image avant Nexus
# ============================================================

echo "[*] Scénario 7: Trivy - Rejet image vulnérable"
echo ""

# Créer un Dockerfile avec image ancienne (vulnérabilités connues)
mkdir -p /tmp/vuln-docker
cat > /tmp/vuln-docker/Dockerfile <<'DEOF'
# Image ancienne avec vulnérabilités connues
FROM python:3.8.0

WORKDIR /app

# Dépendances avec vulnérabilités connues
RUN pip install \
    django==2.0.0 \
    cryptography==2.0 \
    requests==2.18.0 \
    pillow==5.0.0

COPY app_vuln.py .

CMD ["python", "app_vuln.py"]
DEOF

cp /tmp/vuln-test/app_vuln.py /tmp/vuln-docker/ 2>/dev/null || \
    echo "print('test')" > /tmp/vuln-docker/app_vuln.py

echo "[+] Dockerfile créé avec image python:3.8.0 (vulnérable)"
echo ""

# Build l'image si Docker disponible
if command -v docker &>/dev/null; then
    echo "[*] Build de l'image vulnérable..."
    docker build -t test-vuln-image:latest /tmp/vuln-docker/ 2>&1 | tail -3

    echo ""
    echo "[*] Scan Trivy de l'image..."
    trivy image test-vuln-image:latest \
        --severity HIGH,CRITICAL \
        --exit-code 1 \
        --format table 2>&1 | head -50 || \
    echo "[+] ✅ Trivy a bloqué l'image (exit code 1) → PAS envoyée à Nexus"

    # Nettoyage
    docker rmi test-vuln-image:latest 2>/dev/null || true
else
    echo "[!] Docker non disponible sur cette machine"
    echo "[*] Lance ce script sur la VM RHEL 9 après déploiement"
fi

echo ""
echo "[+] Scénario Trivy terminé ✓"
echo "[+] Dans le pipeline CI/CD:"
echo "    - Trivy détecte les CVE CRITICAL/HIGH"
echo "    - exit-code: 1 → pipeline FAILED"
echo "    - L'image n'atteint JAMAIS Nexus"
