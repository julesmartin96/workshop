#!/bin/sh
# Point d'entrée du conteneur Mosquitto (voir "entrypoint" dans docker-compose.yml).
# 1. Génère le fichier des comptes MQTT à partir des mots de passe du .env
# 2. Lance Mosquitto (commande passée en argument)
# Si un mot de passe manque, le conteneur s'arrête : jamais de broker sans comptes.
set -eu

: "${MQTT_ESP_PASSWORD:?MQTT_ESP_PASSWORD manquant ou vide dans .env}"
: "${MQTT_API_PASSWORD:?MQTT_API_PASSWORD manquant ou vide dans .env}"

# Retire un éventuel \r (fichier .env enregistré avec des fins de ligne Windows)
ESP_PASS=$(printf '%s' "$MQTT_ESP_PASSWORD" | tr -d '\r')
API_PASS=$(printf '%s' "$MQTT_API_PASSWORD" | tr -d '\r')

# /tmp est un tmpfs : le fichier n'existe qu'en mémoire, lisible par Mosquitto seul
umask 077
F=/tmp/passwd
rm -f "$F"
touch "$F"
mosquitto_passwd -b "$F" esp "$ESP_PASS" >/dev/null
mosquitto_passwd -b "$F" api "$API_PASS" >/dev/null
echo "gen-passwd: comptes MQTT générés : $(cut -d: -f1 "$F" | tr '\n' ' ')"

exec "$@"
