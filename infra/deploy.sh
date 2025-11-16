#!/bin/bash

# Azure AI Foundry NLP Solution Deployment Script
# This script deploys the infrastructure and sets up the Python environment

set -e  # Exit on any error

echo "🚀 Starting Azure AI Foundry NLP Solution Deployment..."

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    echo "❌ Error: main.tf not found. Please run this script from the infra directory."
    exit 1
fi

echo "📋 Step 1: Deploying Azure Infrastructure..."

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "   Initializing Terraform..."
    terraform init
fi

# Deploy infrastructure
echo "   Applying Terraform configuration..."
terraform apply -auto-approve

echo "✅ Infrastructure deployment completed!"

echo "📋 Step 2: Setting up Python environment..."

# Check if .env file was created
if [ -f "../python/.env" ]; then
    echo "   ✅ Environment file (.env) created successfully"
    echo "   📄 Environment variables available:"
    echo "      - AZURE_AI_SERVICES_ENDPOINT"
    echo "      - AZURE_AI_SERVICES_KEY"
    echo "      - AZURE_KEY_VAULT_URI"
    echo "      - AZURE_STORAGE_CONNECTION_STRING"
else
    echo "   ❌ Warning: .env file not created. Check Terraform outputs."
fi

# Install Python dependencies
echo "   Installing Python dependencies..."
cd ../python

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "   Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
echo "   Installing dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "✅ Python environment setup completed!"

echo "🎉 Deployment Complete!"
echo ""
echo "📋 Next Steps:"
echo "   1. Activate the Python environment: cd python && source venv/bin/activate"
echo "   2. Run the PII redactor: python pii_redactor.py"
echo "   3. Check Azure resources in the portal: https://portal.azure.com"
echo ""
echo "📊 Infrastructure Summary:"
terraform output -no-color