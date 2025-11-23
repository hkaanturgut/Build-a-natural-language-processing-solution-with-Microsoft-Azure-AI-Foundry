#!/bin/bash
# make sure to run chmod +x update-env.sh to make it executable
# Update python/.env with the latest Key Vault URI from Terraform outputs
cd "$(dirname "$0")/../infra"
echo "KEY_VAULT_URI=$(terraform output -raw key_vault_uri)" > ../python/.env
