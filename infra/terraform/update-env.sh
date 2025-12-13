#!/bin/bash
# make sure to run chmod +x update-env.sh to make it executable
# Update python/.env with the latest Key Vault URI from Terraform outputs

# Find the python/.env path dynamically
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
PYTHON_ENV_PATH="$PROJECT_ROOT/python/.env"

# Verify python directory exists
if [ ! -d "$PROJECT_ROOT/python" ]; then
  echo "Error: python directory not found at $PROJECT_ROOT/python"
  exit 1
fi

# Change to infra directory to run terraform
cd "$PROJECT_ROOT/infra" || exit 1

# Export Terraform outputs to python/.env
echo "KEY_VAULT_URI=$(terraform output -raw key_vault_uri)" > "$PYTHON_ENV_PATH"
echo "Updated $PYTHON_ENV_PATH with Terraform outputs"
