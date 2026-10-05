#!/usr/bin/env bash
# Pare-feu des conteneurs (serveur LINUX uniquement).
# Docker contourne UFW pour les ports publiés : ces règles vont dans la chaîne
# DOCKER-USER, que Docker consulte AVANT ses propres règles.
# Usage : sudo WIFI_IF=wlan0 ./docker-user.sh      (à relancer après chaque redémarrage)
set -euo pipefail

WIFI_IF="${WIFI_IF:-wlan0}"        # interface du point d'accès de la table
LAN="${LAN:-192.168.10.0/24}"      # réseau de la table

iptables -N DOCKER-USER 2>/dev/null || true
iptables -F DOCKER-USER

# 1. Réponses aux connexions déjà acceptées
iptables -A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN

# 2. Depuis le WiFi : seules les adresses de la table
iptables -A DOCKER-USER -i "$WIFI_IF" ! -s "$LAN" -j DROP

# 3. MQTTS (8883) : 5 connexions simultanées max par IP, 10 nouvelles/s max par IP
iptables -A DOCKER-USER -i "$WIFI_IF" -p tcp -m conntrack --ctstate NEW --ctorigdstport 8883 \
  -m connlimit --connlimit-above 5 --connlimit-mask 32 -j DROP
iptables -A DOCKER-USER -i "$WIFI_IF" -p tcp -m conntrack --ctstate NEW --ctorigdstport 8883 \
  -m hashlimit --hashlimit-name mqtt --hashlimit-mode srcip \
  --hashlimit-above 10/second --hashlimit-burst 20 -j DROP
iptables -A DOCKER-USER -i "$WIFI_IF" -p tcp -m conntrack --ctstate NEW --ctorigdstport 8883 -j RETURN

# 4. HTTPS (443) : 30 connexions simultanées max par IP, 20 nouvelles/s max par IP
iptables -A DOCKER-USER -i "$WIFI_IF" -p tcp -m conntrack --ctstate NEW --ctorigdstport 443 \
  -m connlimit --connlimit-above 30 --connlimit-mask 32 -j DROP
iptables -A DOCKER-USER -i "$WIFI_IF" -p tcp -m conntrack --ctstate NEW --ctorigdstport 443 \
  -m hashlimit --hashlimit-name https --hashlimit-mode srcip \
  --hashlimit-above 20/second --hashlimit-burst 40 -j DROP
iptables -A DOCKER-USER -i "$WIFI_IF" -p tcp -m conntrack --ctstate NEW --ctorigdstport 443 -j RETURN

# 5. Tout le reste venant du WiFi vers les conteneurs : refusé
iptables -A DOCKER-USER -i "$WIFI_IF" -j DROP

# 6. Autres flux (trafic interne Docker, sorties) : inchangés
iptables -A DOCKER-USER -j RETURN

iptables -L DOCKER-USER -n -v --line-numbers
