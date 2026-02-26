#!/bin/bash
# =============================================================================
# Create a Service Principal with Federated Credentials for GitHub Actions
# =============================================================================
# This script creates an Azure AD App Registration / SPN and configures
# federated identity credentials for GitHub Actions OIDC authentication.
# =============================================================================

set -euo pipefail

# ---------------------
# Variables
# ---------------------
APP_NAME="spn-github-nlp-dev-test"
SUBSCRIPTION_ID="52513787-3db1-4afb-845e-922fd437040e"

# GitHub Details
GITHUB_ORG="hkaanturgut"
GITHUB_REPO="Build-a-natural-language-processing-solution-with-Microsoft-Azure-AI-Foundry"
ENTITY_TYPE="environment"  # environment, branch, tag, pull_request
ENVIRONMENT="dev"

# Federated Credential Details
CREDENTIAL_NAME="dev"
CREDENTIAL_DESCRIPTION="GitHub Actions federated credential for dev environment"

# ---------------------
# Step 1: Create Azure AD App Registration
# ---------------------
echo "Creating Azure AD App Registration: $APP_NAME ..."

APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)
echo "App Registration created. Application (Client) ID: $APP_ID"

# ---------------------
# Step 2: Create a Service Principal for the App
# ---------------------
echo "Creating Service Principal for App ID: $APP_ID ..."

SPN_OBJECT_ID=$(az ad sp create --id "$APP_ID" --query id --output tsv)
echo "Service Principal created. Object ID: $SPN_OBJECT_ID"

# ---------------------
# Step 3: Create Federated Identity Credential
# ---------------------
echo "Creating Federated Identity Credential: $CREDENTIAL_NAME ..."

SUBJECT="repo:${GITHUB_ORG}/${GITHUB_REPO}:${ENTITY_TYPE}:${ENVIRONMENT}"

az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"${CREDENTIAL_NAME}\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"${SUBJECT}\",
    \"description\": \"${CREDENTIAL_DESCRIPTION}\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

echo "Federated Identity Credential created successfully."

# ---------------------
# Summary
# ---------------------
echo ""
echo "============================================="
echo "  Setup Complete"
echo "============================================="
echo "  App Name:          $APP_NAME"
echo "  Client ID:         $APP_ID"
echo "  SPN Object ID:     $SPN_OBJECT_ID"
echo "  Subscription ID:   $SUBSCRIPTION_ID"
echo ""
echo "  Federated Credential:"
echo "    Name:            $CREDENTIAL_NAME"
echo "    Subject:         $SUBJECT"
echo "    Issuer:          https://token.actions.githubusercontent.com"
echo "    Audience:        api://AzureADTokenExchange"
echo "============================================="
echo ""
echo "Add the following secrets to your GitHub repo:"
echo "  AZURE_CLIENT_ID     = $APP_ID"
echo "  AZURE_TENANT_ID     = $(az account show --query tenantId --output tsv)"
echo "  AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"
echo ""
echo "Use 'azure/login@v2' with OIDC in your GitHub Actions workflow."
