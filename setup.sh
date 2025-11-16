#!/bin/bash

# Script to set up Terraform with environment variables
# This script loads the .env file and exports the variables for Terraform

set -e

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo "📝 Please copy .env.example to .env and set your values:"
    echo "   cp .env.example .env"
    echo "   # Then edit .env with your subscription ID"
    exit 1
fi

# Load environment variables from .env file
echo "📋 Loading environment variables from .env file..."
export $(grep -v '^#' .env | xargs)

# Check if required variables are set
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    echo "❌ AZURE_SUBSCRIPTION_ID not set in .env file"
    exit 1
fi

echo "✅ Environment variables loaded successfully"
echo "📊 Using Azure Subscription: $AZURE_SUBSCRIPTION_ID"

# Navigate to infra directory
cd infra

# Check if terraform.tfvars exists, if not copy from example
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    # Replace the placeholder with the actual subscription ID
    sed -i.bak "s/your-subscription-id-here/$AZURE_SUBSCRIPTION_ID/g" terraform.tfvars
    rm terraform.tfvars.bak
    echo "✅ terraform.tfvars created with your subscription ID"
    echo "📝 Please review and customize terraform.tfvars as needed"
fi

echo ""
echo "🚀 Ready to deploy! Run the following commands:"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"