# AI-SecOps DevSecOps
**Rayen Sliti - Tek-Up University | Projet Universitaire 2026**

Plateforme SOC basée sur Wazuh avec pipeline DevSecOps complet sur RHEL 9.

---

## Démarrage rapide (VM RHEL 9 prête)

```bash
# 1. Cloner le repo
git clone https://github.com/TON-USERNAME/ai-secops.git
cd ai-secops

# 2. Installer toutes les dépendances (Docker, Ansible, Terraform, Trivy...)
sudo bash install.sh

# 3. Générer les certificats Wazuh
cd docker/wazuh
bash generate-certs.sh

# 4. Démarrer Wazuh SIEM
docker compose up -d

# 5. Démarrer le stack DevSecOps
cd ..
docker compose -f docker-compose.devsecops.yml up -d

# 6. Vérifier
docker ps
```

---

## Architecture

```
GitHub (code, IaC, playbooks)
    ↓
CI/CD Pipeline (GitHub Actions):
  Gitleaks → SonarQube SAST → Lint IaC → Trivy → Nexus → Ansible Deploy
                                ↓
SOC Platform (Docker Compose sur RHEL 9):
  Wazuh Manager + Indexer + Dashboard  ←→  Prometheus + Grafana
       ↓                                           ↓
  Linux Agents / Wazuh Rules               Node Exporter / cAdvisor
       ↓
  Kali Linux (lab isolé - scénarios d'attaque)
```

## Stack technique

| Composant | Technologie | Port |
|-----------|-------------|------|
| SIEM | Wazuh 4.7.3 | 443 |
| Indexer | OpenSearch | 9200 |
| SAST | SonarQube Community | 9000 |
| Registry | Nexus Repository | 8081/8082 |
| Métriques | Prometheus | 9090 |
| Dashboards | Grafana | 3000 |
| Scan images | Trivy | CLI |
| Secrets | Gitleaks | CI/CD |
| IaC | Terraform + Ansible | - |

## Scénarios de validation

| # | Scénario | MITRE | Script |
|---|----------|-------|--------|
| 1 | SSH Brute Force | T1110.001 | `attack-scenarios/01_ssh_bruteforce.sh` |
| 2 | FIM - Fichier modifié | T1098 | `attack-scenarios/02_fim_test.sh` |
| 3 | SCA avant/après Ansible | M1028 | `attack-scenarios/03_sca_compliance.sh` |
| 4 | SonarQube Quality Gate | - | `attack-scenarios/04_sonarqube_vuln.sh` |
| 5 | Trivy image rejetée | - | `attack-scenarios/05_trivy_vuln_image.sh` |

## Prérequis VM

- OS: RHEL 9.x
- RAM: 12 Go minimum (8 Go mode dégradé)
- Disque: 100 Go
- CPU: 4 vCPU
- Réseau: accès internet (NAT VMware)

## Secrets GitHub à configurer

```
SONAR_TOKEN      → Token SonarQube
SONAR_URL        → http://VM-IP:9000
NEXUS_URL        → VM-IP:8082
NEXUS_USERNAME   → admin
NEXUS_PASSWORD   → (mot de passe Nexus)
SSH_PRIVATE_KEY  → Clé SSH pour Ansible deploy
VM_HOST          → IP de la VM
```

## Progression

Voir [PROGRESS.md](PROGRESS.md) pour l'état détaillé du projet.
