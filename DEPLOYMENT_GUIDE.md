# Azure Logic App Deployment - SQL to Oracle Data Sync

This repository contains Infrastructure as Code (IaC) using Bicep to deploy an Azure Logic App (Consumption Plan) that synchronizes data from SQL Server to Oracle Database. This solution migrates the functionality previously implemented in Boomi.

## 📋 Overview

The Logic App performs the following operations:
1. **Triggers** when a new row is added to the SQL Server `Customer` table
2. **Transforms** the data (field mapping):
   - `CustomerId` → `id`
   - `Name` → `fullName`
   - `Email` → `emailAddress`
3. **Inserts** the transformed data into Oracle Database `CUSTOMERS` table

This mirrors the Boomi process defined in the `Boomi(.DAR)` folder.

## 🏗️ Architecture

```
SQL Server (Customer Table)
    ↓ (Trigger on new row)
Logic App Consumption Plan
    ↓ (Transform data)
Oracle Database (CUSTOMERS Table)
```

### Components

- **Logic App (Consumption Plan)**: Serverless workflow orchestration
- **SQL Server API Connection**: Connects to Azure SQL or SQL Server
- **Oracle Database API Connection**: Connects to Oracle Database
- **Polling Trigger**: Checks for new rows every 60 seconds (configurable)

## 📂 Repository Structure

```
.
├── Boomi(.DAR)/                    # Original Boomi DAR files
│   ├── Components/                 # Boomi components (connections, mappings)
│   ├── Process/                    # Boomi process definitions
│   └── EnvironmentExtensions/      # Environment configurations
├── infrastructure/
│   └── bicep/
│       ├── main.bicep              # Main Bicep template
│       ├── parameters.json         # Parameters (with plain text secrets)
│       └── parameters.keyvault.json # Parameters (with Key Vault references)
├── deploy.sh                       # Deployment script
└── DEPLOYMENT_GUIDE.md            # This file
```

## 🚀 Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed (version 2.40.0 or higher)
   ```bash
   az --version
   ```
   Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

2. **Azure Subscription** with appropriate permissions:
   - Contributor role on the subscription or resource group
   - Ability to create Logic Apps and API Connections

3. **SQL Server Database** configured:
   - Azure SQL Database or on-premises SQL Server
   - `Customer` table with columns: `CustomerId` (int), `Name` (varchar), `Email` (varchar)
   - Network access configured (firewall rules for Azure services)

4. **Oracle Database** configured:
   - Oracle Database accessible from Azure
   - `CUSTOMERS` table with columns: `ID` (NUMBER), `FULL_NAME` (VARCHAR2), `EMAIL_ADDRESS` (VARCHAR2)
   - Oracle Database Gateway (if on-premises) or direct connectivity

## ⚙️ Configuration

### Step 1: Update Parameters File

Edit `infrastructure/bicep/parameters.json` with your configuration:

```json
{
  "parameters": {
    "location": {
      "value": "eastus"  // Your Azure region
    },
    "environment": {
      "value": "dev"  // dev, test, or prod
    },
    "sqlServerName": {
      "value": "your-sql-server.database.windows.net"
    },
    "sqlDatabaseName": {
      "value": "your-database-name"
    },
    "sqlUsername": {
      "value": "your-sql-username"
    },
    "sqlPassword": {
      "value": "your-sql-password"  // Consider using Key Vault
    },
    "oracleHost": {
      "value": "your-oracle-host"
    },
    "oraclePort": {
      "value": "1521"
    },
    "oracleServiceName": {
      "value": "ORCL"
    },
    "oracleUsername": {
      "value": "your-oracle-username"
    },
    "oraclePassword": {
      "value": "your-oracle-password"  // Consider using Key Vault
    },
    "pollingIntervalSeconds": {
      "value": 60  // How often to check for new rows
    }
  }
}
```

### Step 2: (Optional) Use Azure Key Vault for Secrets

For production deployments, use `parameters.keyvault.json` instead:

1. Create an Azure Key Vault
2. Store secrets in Key Vault
3. Update `parameters.keyvault.json` with your Key Vault ID
4. Grant Logic App access to Key Vault

## 🎯 Deployment

### Quick Deployment (Default)

```bash
./deploy.sh
```

This will:
- Create resource group: `rg-sqltoora-dev` in `eastus`
- Deploy all resources
- Display deployment results

### Custom Deployment

```bash
./deploy.sh <resource-group-name> <location>
```

Example:
```bash
./deploy.sh rg-my-logicapp westus2
```

### Manual Deployment (Alternative)

If you prefer manual control:

```bash
# 1. Login to Azure
az login

# 2. Set subscription
az account set --subscription "Your Subscription Name"

# 3. Create resource group
az group create --name rg-sqltoora-dev --location eastus

# 4. Deploy Bicep template
az deployment group create \
  --name logicapp-deployment \
  --resource-group rg-sqltoora-dev \
  --template-file infrastructure/bicep/main.bicep \
  --parameters infrastructure/bicep/parameters.json
```

## 🧪 Testing

### 1. Verify Deployment

Check the Azure Portal:
```
https://portal.azure.com
→ Resource Groups
→ [Your Resource Group]
→ Logic App
```

### 2. Test the Trigger

Add a new row to your SQL Server database:

```sql
INSERT INTO dbo.Customer (CustomerId, Name, Email)
VALUES (1, 'John Doe', 'john.doe@example.com');
```

### 3. Monitor Execution

1. Open the Logic App in Azure Portal
2. Go to "Overview" → "Runs history"
3. Click on the latest run to see execution details
4. Verify each step completed successfully

### 4. Verify Oracle Database

Check that the data was inserted:

```sql
SELECT * FROM CUSTOMERS WHERE ID = 1;
```

Expected result:
```
ID: 1
FULL_NAME: John Doe
EMAIL_ADDRESS: john.doe@example.com
```

## 🔧 Troubleshooting

### Common Issues

#### 1. SQL Connection Failed
- Verify SQL Server firewall allows Azure services
- Check username/password are correct
- Ensure database exists and is accessible

#### 2. Oracle Connection Failed
- Verify Oracle host is accessible from Azure
- Check Oracle Database Gateway (if on-premises)
- Confirm Oracle service name is correct

#### 3. Logic App Not Triggering
- Check that the Customer table exists
- Verify the table has the correct schema
- Check Logic App is enabled (not disabled)
- Review polling interval setting

#### 4. Deployment Fails
- Ensure you have appropriate Azure permissions
- Verify parameters.json has no syntax errors
- Check that resource names are unique and valid

### View Logic App Logs

```bash
# Get recent runs
az logicapp show --name <logic-app-name> --resource-group <resource-group>

# View run history in portal
https://portal.azure.com/#resource/<logic-app-id>/runs
```

## 📊 Monitoring

### Azure Monitor Integration

The Logic App automatically integrates with Azure Monitor:

1. **Metrics**: View in Azure Portal → Logic App → Metrics
   - Run count
   - Success rate
   - Latency

2. **Alerts**: Set up alerts for failures
   ```bash
   az monitor metrics alert create \
     --name "Logic App Failure Alert" \
     --resource-group <rg-name> \
     --scopes <logic-app-id> \
     --condition "count Failed Runs > 0"
   ```

3. **Log Analytics**: Enable diagnostic settings for detailed logs

## 💰 Cost Considerations

**Logic App Consumption Plan Pricing**:
- Pay per execution
- First 4,000 executions free per month
- Additional executions: ~$0.000025 per execution

**Estimated Monthly Cost** (assuming 1 new row per minute):
- Executions: ~43,200/month
- Cost: ~$1-2/month

See: https://azure.microsoft.com/en-us/pricing/details/logic-apps/

## 🔒 Security Best Practices

1. **Use Azure Key Vault** for all secrets
2. **Enable Managed Identity** for the Logic App
3. **Restrict network access** using private endpoints
4. **Enable diagnostic logging** for audit trails
5. **Use Azure Policy** to enforce security standards
6. **Rotate credentials** regularly

## 🔄 Migration from Boomi

This Logic App replicates the following Boomi process:

| Boomi Component | Logic App Equivalent |
|----------------|---------------------|
| SQL Database Connector | SQL Server API Connection |
| Select Operation | SQL Trigger (new row) |
| Map Component | Compose Action (data transformation) |
| HTTP Connector (Oracle CCS) | Oracle Database API Connection |
| POST Operation | Insert Row Action |

**Field Mappings**:
```
CustomerId → id
Name → fullName
Email → emailAddress
```

## 📚 Additional Resources

- [Azure Logic Apps Documentation](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [SQL Server Connector Reference](https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-sqlazure)
- [Oracle Database Connector Reference](https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-oracledatabase)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure Logic App run history
3. Check Azure Monitor logs
4. Contact your Azure support team

## 📝 License

This is a migration template for Boomi to Azure Logic Apps.

---

**Last Updated**: November 2025
