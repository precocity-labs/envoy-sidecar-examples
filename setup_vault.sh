#!/bin/sh

# Fail on errors
set -e

MY_DOMAIN=precocity-labs.services
VAULT_ROLE=precocity_labs_dot_services
export VAULT_ADDR=http://vault:8200
VAULT_URL=vault:8200


# Enable PKI on Vault
vault secrets enable pki

# Update Root Cert TTL
vault secrets tune -max-lease-ttl=87600h pki

# Create the Root CA
vault write pki/root/generate/internal common_name=$MY_DOMAIN ttl=87600h

# Setup Vault URLs to embed in Certificates
vault write pki/config/urls issuing_certificates="http://$VAULT_URL/v1/pki/ca" crl_distribution_points="http://$VAULT_URL/v1/pki/crl"

# Create Role for Root CA
vault write pki/roles/$VAULT_ROLE \
    allowed_domains=$MY_DOMAIN \
    allow_subdomains=true max_ttl=72h

# Setup backend for intermediate certificates
vault secrets enable -path=pki_int pki

# Set TTL for Intermediate Certs
vault secrets tune -max-lease-ttl=43800h pki_int

# Genreate CSR for Intermediate Cert
INT_CSR=$(vault write --field=csr pki_int/intermediate/generate/internal common_name="$MY_DOMAIN Intermediate Authority" ttl=43800h)

TMP_CSR_FILE=int_cert.csr
echo "$INT_CSR" > $TMP_CSR_FILE

# Generate the Intermediate Cert
INT_CERT=$(vault write --field=certificate pki/root/sign-intermediate csr=@int_cert.csr format=pem_bundle ttl=43800h)

TMP_CERT_FILE=int_cert.pem
echo "$INT_CERT" > $TMP_CERT_FILE

# Set Intermediate Certs Signing Auth to Root Cert
vault write pki_int/intermediate/set-signed certificate=@$TMP_CERT_FILE

# Remove the Temp files
rm -f $TMP_CERT_FILE
rm -f $TMP_CSR_FILE

# Set URL Config for Certs Issues from Intermediate Cert
vault write pki_int/config/urls issuing_certificates="http://$VAULT_URL/v1/pki_int/ca" crl_distribution_points="http://$VAULT_URL/v1/pki_int/crl"

# Configure Role for Intermediate Cert
vault write pki_int/roles/$VAULT_ROLE \
    allowed_domains=$MY_DOMAIN \
    allow_subdomains=true max_ttl=72h

# TODO: Enable App Roles in this script as well

echo "Initial Vault PKI setup complete.  Ready to issue certificates."


