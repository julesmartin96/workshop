#!/usr/bin/env bash
# Génère la CA et le certificat serveur (EC P-256) dans infra/pki/out/
# A lancer depuis Git Bash. Ne jamais commiter out/ (sauf ca.crt si besoin).
set -euo pipefail
export MSYS_NO_PATHCONV=1   # empêche Git Bash de transformer "/CN=..." en chemin Windows

cd "$(dirname "$0")"
mkdir -p out && cd out

if [ -f ca.key ]; then
  echo "out/ca.key existe déjà : supprimez out/ pour régénérer." >&2
  exit 1
fi

# 1. Autorité de certification
openssl ecparam -name prime256v1 -genkey -noout -out ca.key
openssl req -x509 -new -key ca.key -sha256 -days 365 \
  -subj "/CN=Sentinel-X CA" -out ca.crt

# 2. Certificat du serveur, signé par la CA
openssl ecparam -name prime256v1 -genkey -noout -out server.key
openssl req -new -key server.key -subj "/CN=sentinel.lan" -out server.csr
cat > server.ext <<EXT
basicConstraints=CA:FALSE
keyUsage=digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=DNS:sentinel.lan,DNS:mosquitto,DNS:localhost,IP:192.168.10.1,IP:127.0.0.1
EXT
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 120 -sha256 -extfile server.ext -out server.crt
rm -f server.csr server.ext ca.srl

openssl verify -CAfile ca.crt server.crt
