#!/bin/sh
# Génère le login du dashboard à partir du .env, à chaque démarrage de nginx.
# Monté dans /docker-entrypoint.d/ : l'image nginx l'exécute avant de lancer nginx.
# Si le mot de passe manque, le conteneur s'arrête (pas de site ouvert sans login).
set -eu

: "${DASHBOARD_PASSWORD:?DASHBOARD_PASSWORD manquant ou vide dans .env}"
USER_NAME=$(printf '%s' "${DASHBOARD_USER:-admin}" | tr -d '\r')
PASS=$(printf '%s' "$DASHBOARD_PASSWORD" | tr -d '\r')

# /tmp est un tmpfs : le fichier n'existe qu'en mémoire, jamais sur le disque
printf '%s:%s\n' "$USER_NAME" "$(cryptpw -m sha512 "$PASS")" > /tmp/htpasswd
chown root:nginx /tmp/htpasswd
chmod 640 /tmp/htpasswd

echo "gen-htpasswd: login du dashboard généré pour '$USER_NAME'"
