# Configuration Guide

## Configuration Options

You have 3 options for managing configuration:

### Option 1: Direct Parameters (Quick & Simple)
Edit `infrastructure/bicep/parameters.json` directly with your values.

**Pros**: Quick to set up
**Cons**: Secrets visible in plain text

### Option 2: Environment Variables
Use environment variables and a deployment script.

Create `.env` file:
```bash
# Azure Configuration
AZURE_LOCATION=eastus
ENVIRONMENT=dev

# SQL Server Configuration
SQL_SERVER_NAME=myserver.database.windows.net
SQL_DATABASE_NAME=mydb
SQL_USERNAME=sqladmin
SQL_PASSWORD=MySecurePassword123!

# Oracle Configuration
ORACLE_HOST=oracle.example.com
ORACLE_PORT=1521
ORACLE_SERVICE_NAME=ORCL
ORACLE_USERNAME=oracleadmin
ORACLE_PASSWORD=MyOraclePassword123!

# Logic App Configuration
POLLING_INTERVAL_SECONDS=60
```

Then use an enhanced deployment script (see below).

**Pros**: Keeps secrets out of source control
**Cons**: Requires additional scripting

### Option 3: Azure Key Vault (Recommended for Production)
Store all secrets in Azure Key Vault.

1. Create Key Vault:
```bash
az keyvault create \
  --name mykeyvault \
  --resource-group myrg \
  --location eastus
```

2. Store secrets:
```bash
az keyvault secret set --vault-name mykeyvault --name sqlPassword --value "MySecurePassword123!"
az keyvault secret set --vault-name mykeyvault --name oraclePassword --value "MyOraclePassword123!"
```

3. Update `parameters.keyvault.json` with your Key Vault ID
4. Deploy using the Key Vault parameters file

**Pros**: Most secure, production-ready
**Cons**: More setup required

## Environment-Based Deployment Script

Save as `deploy-with-env.sh`:

```bash
#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found"
    exit 1
fi

# Deploy with inline parameters
az deployment group create \
  --resource-group "rg-sqltoora-${ENVIRONMENT}" \
  --template-file infrastructure/bicep/main.bicep \
  --parameters \
    location="${AZURE_LOCATION}" \
    environment="${ENVIRONMENT}" \
    sqlServerName="${SQL_SERVER_NAME}" \
    sqlDatabaseName="${SQL_DATABASE_NAME}" \
    sqlUsername="${SQL_USERNAME}" \
    sqlPassword="${SQL_PASSWORD}" \
    sqlConnectionString="Server=tcp:${SQL_SERVER_NAME},1433;Database=${SQL_DATABASE_NAME};User ID=${SQL_USERNAME};Password=${SQL_PASSWORD};Encrypt=True;" \
    oracleHost="${ORACLE_HOST}" \
    oraclePort="${ORACLE_PORT}" \
    oracleServiceName="${ORACLE_SERVICE_NAME}" \
    oracleUsername="${ORACLE_USERNAME}" \
    oraclePassword="${ORACLE_PASSWORD}" \
    oracleConnectionString="Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=${ORACLE_HOST})(PORT=${ORACLE_PORT}))(CONNECT_DATA=(SERVICE_NAME=${ORACLE_SERVICE_NAME})));User Id=${ORACLE_USERNAME};Password=${ORACLE_PASSWORD};" \
    pollingIntervalSeconds="${POLLING_INTERVAL_SECONDS}"
```

## Database Setup

### SQL Server Table
```sql
CREATE TABLE dbo.Customer (
    CustomerId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Active BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Add index for better trigger performance
CREATE INDEX IX_Customer_CreatedDate ON dbo.Customer(CreatedDate);
```

### Oracle Table
```sql
CREATE TABLE CUSTOMERS (
    ID NUMBER PRIMARY KEY,
    FULL_NAME VARCHAR2(100) NOT NULL,
    EMAIL_ADDRESS VARCHAR2(100) NOT NULL,
    CREATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sequence for ID
CREATE SEQUENCE CUSTOMERS_SEQ START WITH 1 INCREMENT BY 1;

-- Optional: Add trigger for auto-increment
CREATE OR REPLACE TRIGGER CUSTOMERS_BIR
BEFORE INSERT ON CUSTOMERS
FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN
        SELECT CUSTOMERS_SEQ.NEXTVAL INTO :NEW.ID FROM DUAL;
    END IF;
END;
/
```

## Security Recommendations

### 1. Use Managed Identity
Enable system-assigned managed identity for the Logic App and grant it access to resources.

### 2. Add to .gitignore
```
.env
*.env
parameters.json
secrets/
```

### 3. Network Security
- Use Private Endpoints for Logic App
- Restrict SQL Server firewall to Azure services only
- Use VPN/ExpressRoute for Oracle Database

### 4. Credential Rotation
Set up automatic rotation for:
- SQL Server passwords
- Oracle Database passwords
- API connection keys

## Monitoring Configuration

### Enable Application Insights
Add to Bicep:
```bicep
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appinsights-${resourcePrefix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
```

### Configure Alerts
```bash
# Alert on Logic App failures
az monitor metrics alert create \
  --name "LogicApp-Failure-Alert" \
  --resource-group <rg-name> \
  --scopes <logic-app-id> \
  --condition "count FailedRuns > 0" \
  --description "Alert when Logic App fails" \
  --evaluation-frequency 5m \
  --window-size 5m
```

## Performance Tuning

### Adjust Polling Interval
- **Fast sync**: 30 seconds (higher cost)
- **Standard**: 60 seconds (balanced)
- **Slow sync**: 300 seconds (lower cost)

### Optimize SQL Query
Add WHERE clause to reduce data:
```sql
SELECT CustomerId, Name, Email 
FROM dbo.Customer 
WHERE Active = 1 
  AND ModifiedDate > DATEADD(minute, -2, GETDATE())
```

### Batch Processing
For high-volume scenarios, consider batching:
- Remove `splitOn` to process multiple rows together
- Add ForEach loop in Logic App

## Troubleshooting

### Test Connections
```bash
# Test SQL Server connection
sqlcmd -S your-server.database.windows.net -d your-db -U username -P password -Q "SELECT 1"

# Test Oracle connection
sqlplus username/password@//oracle-host:1521/ORCL
```

### View Detailed Logs
```bash
# Enable diagnostic settings
az monitor diagnostic-settings create \
  --name "logicapp-diagnostics" \
  --resource <logic-app-id> \
  --workspace <log-analytics-workspace-id> \
  --logs '[{"category": "WorkflowRuntime", "enabled": true}]'
```

---

For more information, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
