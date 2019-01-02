#!/bin/sh

set -e

VAULT_ROLE=precocity_labs_dot_services

# Quick Hack to ensure all the vault config completes
echo "Service sleeping to allow Vault setup to complete"
sleep 5

# Load Root CA into system
ROOT_CERT=$(vault read --format=json pki/cert/ca | jq -r .data.certificate)
echo "$ROOT_CERT" > /usr/local/share/ca-certificates/precocity-root.crt
update-ca-certificates

# Generate Certificates
CERT_OUTPUT=$(vault write --format=json pki_int/issue/$VAULT_ROLE common_name=$APP_DOMAIN)

PRIVATE_KEY=$(echo "$CERT_OUTPUT" | jq -r .data.private_key)
CERT=$(echo "$CERT_OUTPUT" | jq -r .data.certificate)
CA_CHAIN=$(echo "$CERT_OUTPUT" | jq -r .data.ca_chain[0])

echo "$PRIVATE_KEY" > /etc/precocity-labs.key
echo "$CERT" > /etc/precocity-labs-svc.crt
echo "$CA_CHAIN" > /etc/precocity-labs-int.crt

cat /etc/precocity-labs-svc.crt /etc/precocity-labs-int.crt > /etc/precocity-labs.crt

python3 /code/service.py &
envoy -c /etc/service-envoy.yaml --service-cluster service${SERVICE_NAME}