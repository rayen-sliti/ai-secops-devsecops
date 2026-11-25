# AI-SecOps DevSecOps - Progression
# Rayen Sliti - Tek-Up University

## État actuel: Code prêt, VM en attente

---

## ✅ FAIT (code généré, prêt à déployer)

### Infrastructure
- [x] Structure complète du repo GitHub
- [x] Docker Compose Wazuh (Manager + Indexer + Dashboard 4.7.3)
- [x] Docker Compose DevSecOps (SonarQube + Nexus + Prometheus + Grafana + cAdvisor)
- [x] Prometheus alerting rules (CPU, RAM, disk, container down)
- [x] Script bootstrap RHEL 9 (`install.sh`) - installe tout en 1 commande

### CI/CD Pipeline
- [x] GitHub Actions pipeline complet:
  - Gitleaks (détection secrets)
  - SonarQube SAST + Quality Gate
  - Lint Terraform + Ansible
  - Build Docker image
  - Trivy scan (CRITICAL/HIGH bloquant)
  - Push Nexus (uniquement si tout passe)
  - Déploiement Ansible

### Ansible
- [x] Role `hardening` (CIS Benchmark niveau 1 RHEL 9)
- [x] Role `wazuh-agent` (installation + configuration Linux)
- [x] Role `docker-install`
- [x] Playbook principal `site.yml`
- [x] Template `ossec.conf` (FIM + SCA + logs)

### Scénarios de validation (EF-04)
- [x] Scénario 1: SSH Brute Force → Wazuh alert T1110.001
- [x] Scénario 2: FIM - Modification /etc → Alerte intégrité
- [x] Scénario 3: SCA Compliance avant/après Ansible
- [x] Scénario 4: SonarQube Quality Gate - code vulnérable bloqué
- [x] Scénario 5: Trivy - image Docker vulnérable rejetée

---

## 🔄 À FAIRE (demain après VM prête)

### Déploiement VM RHEL 9
- [ ] Lancer la VM avec 12 Go RAM (après suppression VMs PCA)
- [ ] `sudo bash install.sh` (bootstrap complet)
- [ ] `cd docker/wazuh && bash generate-certs.sh`
- [ ] `docker compose up -d` (Wazuh)
- [ ] `docker compose -f docker-compose.devsecops.yml up -d`
- [ ] Vérifier Wazuh Dashboard: https://localhost:443

### Configuration
- [ ] Mettre l'IP de la VM dans `ansible/inventory/hosts.yml`
- [ ] Configurer les secrets GitHub (SONAR_TOKEN, NEXUS_*, SSH_KEY)
- [ ] Configurer SonarQube project + Quality Gate
- [ ] Configurer Nexus Docker registry
- [ ] Importer dashboards Grafana (Node Exporter Full: ID 1860)

### Tests de validation
- [ ] Exécuter scénario 1 (SSH brute force depuis Kali)
- [ ] Exécuter scénario 2 (FIM test)
- [ ] Exécuter scénario 3 (SCA avant/après)
- [ ] Exécuter scénario 4 (SonarQube pipeline)
- [ ] Exécuter scénario 5 (Trivy image)
- [ ] Capturer les screenshots pour le rapport

### Terraform (optionnel si VM déjà créée manuellement)
- [ ] Modules réseau + VM (si besoin d'automatiser)

---

## 📋 Sprints (Cahier des charges)

| Sprint | Description | Statut |
|--------|-------------|--------|
| S1 | Architecture + backlog | ✅ |
| S2 | SOC - Wazuh Docker + premier agent | 🔄 Code prêt |
| S3 | Endpoints - Windows+Sysmon (binômes) | ⏳ |
| S4 | IaC - Terraform + Ansible | 🔄 Code prêt |
| S5 | DevSecOps - CI/CD + SonarQube + Nexus + Trivy | 🔄 Code prêt |
| S6 | Observabilité - Prometheus + Grafana | 🔄 Code prêt |
| S7 | AI SecOps (binômes) | ⏳ |
| S8 | Finalisation | ⏳ |

---

## 🔑 Accès après déploiement

| Service | URL | Credentials |
|---------|-----|-------------|
| Wazuh Dashboard | https://VM-IP:443 | admin / SecurePassword123! |
| SonarQube | http://VM-IP:9000 | admin / admin |
| Nexus | http://VM-IP:8081 | admin / (voir logs premier démarrage) |
| Grafana | http://VM-IP:3000 | admin / admin123 |
| Prometheus | http://VM-IP:9090 | - |

---

## ℹ️ Pour reprendre dans une nouvelle conversation

Dis simplement:
> "Voici mon repo GitHub: [lien], je continue le projet AI-SecOps DevSecOps RHEL 9, la VM est prête"

Le fichier PROGRESS.md et README.md donnent tout le contexte.
