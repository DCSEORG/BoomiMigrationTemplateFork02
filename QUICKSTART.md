# Quick Start Guide

## 🚀 Deploy in 5 Minutes

### Prerequisites
- Azure CLI installed
- Azure subscription access
- SQL Server database with Customer table
- Oracle Database with CUSTOMERS table

### Step 1: Configure
Edit `infrastructure/bicep/parameters.json`:
```json
{
  "parameters": {
    "sqlServerName": { "value": "your-server.database.windows.net" },
    "sqlDatabaseName": { "value": "your-database" },
    "sqlUsername": { "value": "your-username" },
    "sqlPassword": { "value": "your-password" },
    "oracleHost": { "value": "your-oracle-host" },
    "oracleServiceName": { "value": "ORCL" },
    "oracleUsername": { "value": "oracle-user" },
    "oraclePassword": { "value": "oracle-password" }
  }
}
```

### Step 2: Deploy
```bash
./deploy.sh
```

### Step 3: Test
```sql
-- Insert into SQL Server
INSERT INTO dbo.Customer (CustomerId, Name, Email)
VALUES (1, 'Test User', 'test@example.com');

-- Verify in Oracle
SELECT * FROM CUSTOMERS WHERE ID = 1;
```

## ✅ That's It!

Your Logic App is now:
- ✓ Monitoring SQL Server for new rows
- ✓ Transforming data automatically
- ✓ Inserting into Oracle Database

## 📊 Monitor
View runs: https://portal.azure.com → Logic Apps → [Your Logic App] → Runs history

## ❓ Need Help?
See full documentation: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
