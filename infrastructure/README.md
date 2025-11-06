# Infrastructure Overview

This directory contains all Infrastructure as Code (IaC) files for deploying the Azure Logic App solution.

## Directory Structure

```
infrastructure/
├── bicep/
│   ├── main.bicep                    # Main Bicep template
│   ├── parameters.json               # Parameters (plain text)
│   └── parameters.keyvault.json      # Parameters (Key Vault refs)
└── scripts/
    ├── setup-sqlserver.sql           # SQL Server table setup
    └── setup-oracle.sql              # Oracle table setup
```

## Components

### Bicep Templates

#### main.bicep
The main Infrastructure as Code template that deploys:
- **Logic App (Consumption Plan)**: Serverless workflow orchestration
- **SQL Server API Connection**: Connects to SQL Server/Azure SQL
- **Oracle Database API Connection**: Connects to Oracle Database

**Key Features**:
- Configurable polling interval
- Automatic data transformation
- Built-in retry logic
- Integration with Azure Monitor

#### parameters.json
Direct parameter configuration file.

**Usage**: For development and testing
**Security**: Contains secrets in plain text - DO NOT commit to source control

#### parameters.keyvault.json
Parameter file with Azure Key Vault references.

**Usage**: For production deployments
**Security**: References secrets stored in Azure Key Vault

### Database Scripts

#### setup-sqlserver.sql
Creates the SQL Server schema:
- `Customer` table with required columns
- Indexes for performance optimization
- Sample test data
- Triggers for modified date tracking

**Run with**:
```bash
sqlcmd -S your-server.database.windows.net -d your-db -U username -P password -i setup-sqlserver.sql
```

#### setup-oracle.sql
Creates the Oracle schema:
- `CUSTOMERS` table with required columns
- Sequence for auto-incrementing IDs
- Triggers for auto-population
- Indexes for performance

**Run with**:
```bash
sqlplus username/password@//oracle-host:1521/ORCL @setup-oracle.sql
```

## Deployment Options

### Option 1: Quick Deployment (Development)
```bash
# From repository root
./deploy.sh
```

### Option 2: Custom Resource Group
```bash
./deploy.sh my-resource-group westus2
```

### Option 3: Manual Deployment
```bash
az deployment group create \
  --resource-group my-rg \
  --template-file infrastructure/bicep/main.bicep \
  --parameters infrastructure/bicep/parameters.json
```

### Option 4: With Key Vault
```bash
az deployment group create \
  --resource-group my-rg \
  --template-file infrastructure/bicep/main.bicep \
  --parameters infrastructure/bicep/parameters.keyvault.json
```

## Resource Naming Convention

Resources are named using the pattern: `{prefix}-{environment}-{resource-type}`

Example:
- Resource Group: `rg-sqltoora-dev`
- Logic App: `sqltoora-dev-logicapp`
- SQL Connection: `sqltoora-dev-sql-connection`
- Oracle Connection: `sqltoora-dev-oracle-connection`

## Parameters Reference

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| location | string | Yes | Azure region | eastus |
| environment | string | Yes | Environment name | dev, test, prod |
| sqlServerName | string | Yes | SQL Server FQDN | myserver.database.windows.net |
| sqlDatabaseName | string | Yes | Database name | mydb |
| sqlUsername | string | Yes | SQL username | sqladmin |
| sqlPassword | securestring | Yes | SQL password | (secure) |
| sqlConnectionString | securestring | Yes | Full connection string | (secure) |
| oracleHost | string | Yes | Oracle host | oracle.example.com |
| oraclePort | string | No | Oracle port (default: 1521) | 1521 |
| oracleServiceName | string | Yes | Oracle service name | ORCL |
| oracleUsername | string | Yes | Oracle username | oracleadmin |
| oraclePassword | securestring | Yes | Oracle password | (secure) |
| oracleConnectionString | securestring | Yes | Full connection string | (secure) |
| pollingIntervalSeconds | int | No | Polling interval (default: 60) | 60 |

## Bicep Modules (Future Enhancement)

For larger deployments, consider modularizing:

```
infrastructure/
├── bicep/
│   ├── main.bicep
│   ├── modules/
│   │   ├── logicapp.bicep
│   │   ├── sql-connection.bicep
│   │   └── oracle-connection.bicep
│   └── parameters/
│       ├── dev.json
│       ├── test.json
│       └── prod.json
```

## Validation

Validate Bicep templates before deployment:

```bash
# Validate syntax
az bicep build --file infrastructure/bicep/main.bicep

# What-if analysis
az deployment group what-if \
  --resource-group my-rg \
  --template-file infrastructure/bicep/main.bicep \
  --parameters infrastructure/bicep/parameters.json
```

## Clean Up

To remove all deployed resources:

```bash
az group delete --name rg-sqltoora-dev --yes --no-wait
```

## Best Practices

1. **Use Key Vault**: Store all secrets in Azure Key Vault
2. **Version Control**: Keep parameters files out of git (use .gitignore)
3. **Naming Convention**: Use consistent resource naming
4. **Resource Tags**: Tag all resources with environment, owner, cost-center
5. **RBAC**: Use least privilege access for service principals
6. **Monitoring**: Enable diagnostic settings for all resources
7. **Cost Management**: Set up budgets and alerts

## Troubleshooting

### Deployment Fails with "InvalidTemplate"
- Check Bicep syntax: `az bicep build --file main.bicep`
- Validate parameters format

### API Connection Authorization Failed
- Verify credentials are correct
- Check network connectivity
- Ensure firewall rules allow Azure services

### Logic App Trigger Not Working
- Verify SQL Server table exists
- Check API connection is authorized
- Review Logic App run history

## Additional Resources

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Logic Apps Bicep Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.logic/workflows)
- [API Connections Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.web/connections)

---

For deployment instructions, see [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md)
