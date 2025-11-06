#!/bin/bash

#############################################################################
# Azure Logic App Deployment Script
# Purpose: Deploy SQL to Oracle data synchronization Logic App
# Usage: ./deploy.sh [resource-group-name] [location]
#############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_LOCATION="eastus"
DEFAULT_RG_NAME="rg-sqltoora-dev"
BICEP_FILE="infrastructure/bicep/main.bicep"
PARAMS_FILE="infrastructure/bicep/parameters.json"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_message "$GREEN" "========================================"
print_message "$GREEN" "Azure Logic App Deployment Script"
print_message "$GREEN" "SQL to Oracle Data Sync (Boomi Migration)"
print_message "$GREEN" "========================================"
echo ""

# Get resource group name from argument or use default
RESOURCE_GROUP=${1:-$DEFAULT_RG_NAME}
LOCATION=${2:-$DEFAULT_LOCATION}

print_message "$YELLOW" "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Bicep File: $BICEP_FILE"
echo "  Parameters File: $PARAMS_FILE"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_message "$RED" "Error: Azure CLI is not installed. Please install it first."
    print_message "$YELLOW" "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

print_message "$GREEN" "✓ Azure CLI is installed"

# Check if user is logged in
print_message "$YELLOW" "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_message "$YELLOW" "Not logged in. Initiating Azure login..."
    az login
else
    print_message "$GREEN" "✓ Already logged in to Azure"
fi

# Display current subscription
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_message "$GREEN" "Current Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo ""

# Confirm deployment
read -p "Do you want to proceed with deployment? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    print_message "$YELLOW" "Deployment cancelled by user."
    exit 0
fi

# Check if Bicep file exists
if [ ! -f "$BICEP_FILE" ]; then
    print_message "$RED" "Error: Bicep file not found at $BICEP_FILE"
    exit 1
fi

# Check if parameters file exists
if [ ! -f "$PARAMS_FILE" ]; then
    print_message "$RED" "Error: Parameters file not found at $PARAMS_FILE"
    print_message "$YELLOW" "Please create the parameters file with your configuration."
    exit 1
fi

# Check if resource group exists, create if not
print_message "$YELLOW" "Checking if resource group exists..."
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_message "$GREEN" "✓ Resource group '$RESOURCE_GROUP' already exists"
else
    print_message "$YELLOW" "Creating resource group '$RESOURCE_GROUP' in location '$LOCATION'..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    print_message "$GREEN" "✓ Resource group created successfully"
fi

echo ""
print_message "$YELLOW" "Starting deployment..."
print_message "$YELLOW" "This may take several minutes..."
echo ""

# Deploy the Bicep template
DEPLOYMENT_NAME="logicapp-deployment-$(date +%Y%m%d-%H%M%S)"

if az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$BICEP_FILE" \
    --parameters "$PARAMS_FILE" \
    --verbose; then
    
    echo ""
    print_message "$GREEN" "========================================"
    print_message "$GREEN" "✓ Deployment completed successfully!"
    print_message "$GREEN" "========================================"
    echo ""
    
    # Get deployment outputs
    print_message "$YELLOW" "Retrieving deployment outputs..."
    LOGIC_APP_NAME=$(az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query properties.outputs.logicAppName.value -o tsv)
    
    LOGIC_APP_ID=$(az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query properties.outputs.logicAppId.value -o tsv)
    
    echo ""
    print_message "$GREEN" "Deployment Details:"
    echo "  Deployment Name: $DEPLOYMENT_NAME"
    echo "  Logic App Name: $LOGIC_APP_NAME"
    echo "  Logic App ID: $LOGIC_APP_ID"
    echo ""
    
    print_message "$YELLOW" "Next Steps:"
    echo "1. Verify the Logic App in Azure Portal"
    echo "2. Test the SQL trigger by adding a new row to the Customer table"
    echo "3. Check the Logic App run history for execution details"
    echo "4. Monitor the Oracle database for inserted records"
    echo ""
    
    print_message "$GREEN" "Portal URL:"
    echo "https://portal.azure.com/#resource${LOGIC_APP_ID}"
    echo ""
    
else
    echo ""
    print_message "$RED" "========================================"
    print_message "$RED" "✗ Deployment failed!"
    print_message "$RED" "========================================"
    echo ""
    print_message "$YELLOW" "Please check the error messages above and:"
    echo "1. Verify your parameters.json file has correct values"
    echo "2. Ensure you have appropriate permissions"
    echo "3. Check that the SQL Server and Oracle Database are accessible"
    exit 1
fi

print_message "$GREEN" "Deployment script completed."
