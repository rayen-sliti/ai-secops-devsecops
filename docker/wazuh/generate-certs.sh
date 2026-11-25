#!/bin/bash
# Génération des certificats SSL pour Wazuh
# À exécuter une seule fois avant le premier démarrage

set -e

echo "[*] Génération des certificats Wazuh..."

docker run --rm \
  -v ./config/wazuh_indexer_ssl_certs:/certs \
  -v ./config/certs.yml:/config/certs.yml \
  wazuh/wazuh-certs-generator:0.0.1 \
  ./tools/certs-tool.sh -A

echo "[+] Certificats générés dans ./config/wazuh_indexer_ssl_certs/"
echo "[*] Tu peux maintenant lancer: docker compose up -d"
