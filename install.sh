#!/bin/bash
# ============================================================
# AI-SecOps DevSecOps - Script Bootstrap RHEL 9
# Auteur: Rayen Sliti - Tek-Up University
# Usage: sudo bash install.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[*]${NC} $1"; }

# ─── Vérifications préalables ─────────────────────────────────
[[ $EUID -ne 0 ]] && err "Lance ce script avec sudo: sudo bash install.sh"
[[ $(nproc) -lt 2 ]] && warn "Minimum 2 CPU recommandés"
RAM_GB=$(awk '/MemTotal/{printf "%.0f", $2/1024/1024}' /proc/meminfo)
[[ $RAM_GB -lt 7 ]] && err "Minimum 8 Go RAM requis (détecté: ${RAM_GB}Go)"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║        AI-SecOps DevSecOps - Installation            ║"
echo "║        Rayen Sliti - Tek-Up University               ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
info "RAM détectée: ${RAM_GB} Go"
info "CPU: $(nproc) cœurs"
info "OS: $(cat /etc/redhat-release)"
echo ""

# ─── 1. Mise à jour système ────────────────────────────────────
log "Mise à jour du système..."
dnf update -y -q
dnf install -y -q curl wget git vim net-tools unzip tar \
    python3 python3-pip python3-devel openssl \
    yum-utils device-mapper-persistent-data lvm2 \
    bash-completion policycoreutils-python-utils

# ─── 2. Docker CE ─────────────────────────────────────────────
log "Installation Docker CE..."
if ! command -v docker &>/dev/null; then
    dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
    usermod -aG docker rayen 2>/dev/null || true
    log "Docker installé: $(docker --version)"
else
    log "Docker déjà installé: $(docker --version)"
fi

# Configuration Docker - limites pour 8-12 Go RAM
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "name": "nofile",
      "hard": 65536,
      "soft": 65536
    }
  },
  "storage-driver": "overlay2"
}
EOF
systemctl restart docker

# ─── 3. Docker Compose standalone (v2) ────────────────────────
log "Vérification Docker Compose..."
if ! docker compose version &>/dev/null; then
    COMPOSE_VERSION="v2.24.5"
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
        -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi
log "Docker Compose: $(docker compose version)"

# ─── 4. Terraform ─────────────────────────────────────────────
log "Installation Terraform..."
if ! command -v terraform &>/dev/null; then
    dnf install -y yum-utils
    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    dnf install -y terraform
    log "Terraform installé: $(terraform version | head -1)"
else
    log "Terraform déjà installé: $(terraform version | head -1)"
fi

# ─── 5. Ansible ───────────────────────────────────────────────
log "Installation Ansible..."
if ! command -v ansible &>/dev/null; then
    pip3 install --quiet ansible ansible-lint
    log "Ansible installé: $(ansible --version | head -1)"
else
    log "Ansible déjà installé: $(ansible --version | head -1)"
fi

# ─── 6. Trivy (scan d'images) ─────────────────────────────────
log "Installation Trivy..."
if ! command -v trivy &>/dev/null; then
    cat > /etc/yum.repos.d/trivy.repo <<'EOF'
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF
    dnf install -y trivy
    log "Trivy installé: $(trivy --version)"
else
    log "Trivy déjà installé"
fi

# ─── 7. Gitleaks (détection secrets) ──────────────────────────
log "Installation Gitleaks..."
if ! command -v gitleaks &>/dev/null; then
    GITLEAKS_VERSION="8.18.2"
    curl -sL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
        | tar -xz -C /usr/local/bin gitleaks
    chmod +x /usr/local/bin/gitleaks
    log "Gitleaks installé: $(gitleaks version)"
else
    log "Gitleaks déjà installé"
fi

# ─── 8. Paramètres kernel pour Wazuh/Elasticsearch ────────────
log "Configuration kernel (Wazuh/Elasticsearch)..."
cat >> /etc/sysctl.conf <<'EOF'
# AI-SecOps - Wazuh/Elasticsearch
vm.max_map_count=262144
vm.swappiness=10
net.core.somaxconn=65535
EOF
sysctl -p -q

# ─── 9. Firewall - ports nécessaires ──────────────────────────
log "Configuration firewall..."
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-port=443/tcp    # Wazuh Dashboard
    firewall-cmd --permanent --add-port=1514/tcp   # Wazuh agents
    firewall-cmd --permanent --add-port=1514/udp
    firewall-cmd --permanent --add-port=1515/tcp   # Wazuh enrollment
    firewall-cmd --permanent --add-port=9200/tcp   # Wazuh Indexer
    firewall-cmd --permanent --add-port=55000/tcp  # Wazuh API
    firewall-cmd --permanent --add-port=9000/tcp   # SonarQube
    firewall-cmd --permanent --add-port=8081/tcp   # Nexus UI
    firewall-cmd --permanent --add-port=8082/tcp   # Nexus Docker
    firewall-cmd --permanent --add-port=3000/tcp   # Grafana
    firewall-cmd --permanent --add-port=9090/tcp   # Prometheus
    firewall-cmd --permanent --add-port=9100/tcp   # Node Exporter
    firewall-cmd --reload
    log "Firewall configuré"
else
    warn "firewalld non actif - ports non configurés"
fi

# ─── 10. SELinux en mode permissif (pour Docker) ──────────────
if getenforce | grep -q "Enforcing"; then
    warn "SELinux en mode permissif pour Docker..."
    setenforce 0
    sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
fi

# ─── Résumé ───────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║              Installation terminée !                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
log "Docker:        $(docker --version)"
log "Docker Compose: $(docker compose version)"
log "Terraform:     $(terraform version | head -1)"
log "Ansible:       $(ansible --version | head -1)"
log "Trivy:         $(trivy --version)"
log "Gitleaks:      $(gitleaks version)"
echo ""
info "Prochaine étape: cd docker/wazuh && bash generate-certs.sh"
info "Puis:           docker compose up -d"
echo ""
warn "IMPORTANT: Déconnecte/reconnecte ton session pour que Docker fonctionne sans sudo"
warn "Ou lance: newgrp docker"
