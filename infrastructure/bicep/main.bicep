// Main Bicep file for Azure Logic App - SQL to Oracle data sync
// Based on Boomi migration template

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, test, prod)')
param environment string = 'dev'

// SQL Server connection string - kept for reference but constructed dynamically
// @description('SQL Server connection string')
// @secure()
// param sqlConnectionString string

@description('SQL Server name')
param sqlServerName string

@description('SQL Database name')
param sqlDatabaseName string

@description('SQL Server username')
param sqlUsername string

@description('SQL Server password')
@secure()
param sqlPassword string

// Oracle connection string - kept for reference but constructed dynamically
// @description('Oracle connection string')
// @secure()
// param oracleConnectionString string

@description('Oracle host')
param oracleHost string

@description('Oracle port')
param oraclePort string = '1521'

@description('Oracle service name')
param oracleServiceName string

@description('Oracle username')
param oracleUsername string

@description('Oracle password')
@secure()
param oraclePassword string

@description('Polling interval in seconds for SQL trigger')
param pollingIntervalSeconds int = 60

var resourcePrefix = 'sqltoora-${environment}'
var logicAppName = '${resourcePrefix}-logicapp'
var sqlApiConnectionName = '${resourcePrefix}-sql-connection'
var oracleApiConnectionName = '${resourcePrefix}-oracle-connection'

// SQL Server API Connection
resource sqlApiConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: sqlApiConnectionName
  location: location
  properties: {
    displayName: 'SQL Server Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sql')
    }
    parameterValues: {
      server: sqlServerName
      database: sqlDatabaseName
      username: sqlUsername
      password: sqlPassword
      authType: 'basic'
    }
  }
}

// Oracle Database API Connection
resource oracleApiConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: oracleApiConnectionName
  location: location
  properties: {
    displayName: 'Oracle Database Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'oracle')
    }
    parameterValues: {
      server: '${oracleHost}:${oraclePort}/${oracleServiceName}'
      username: oracleUsername
      password: oraclePassword
      authType: 'basic'
    }
  }
}

// Logic App - Consumption Plan
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: {
    environment: environment
    purpose: 'SQL to Oracle data synchronization'
    migratedFrom: 'Boomi'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_new_row_is_added': {
          recurrence: {
            frequency: 'Second'
            interval: pollingIntervalSeconds
          }
          splitOn: '@triggerBody()?[\'value\']'
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${sqlServerName}.database.windows.net\'))},@{encodeURIComponent(encodeURIComponent(\'${sqlDatabaseName}\'))}/tables/@{encodeURIComponent(encodeURIComponent(\'[dbo].[Customer]\'))}/onnewitems'
          }
        }
      }
      actions: {
        Transform_Data: {
          runAfter: {}
          type: 'Compose'
          inputs: {
            id: '@triggerBody()?[\'CustomerId\']'
            fullName: '@triggerBody()?[\'Name\']'
            emailAddress: '@triggerBody()?[\'Email\']'
          }
        }
        Insert_into_Oracle: {
          runAfter: {
            Transform_Data: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'oracle\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: {
              ID: '@outputs(\'Transform_Data\')?[\'id\']'
              FULL_NAME: '@outputs(\'Transform_Data\')?[\'fullName\']'
              EMAIL_ADDRESS: '@outputs(\'Transform_Data\')?[\'emailAddress\']'
            }
            path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'CUSTOMERS\'))}/items'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          sql: {
            connectionId: sqlApiConnection.id
            connectionName: sqlApiConnectionName
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sql')
          }
          oracle: {
            connectionId: oracleApiConnection.id
            connectionName: oracleApiConnectionName
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'oracle')
          }
        }
      }
    }
  }
}

// Outputs
output logicAppId string = logicApp.id
output logicAppName string = logicApp.name
output sqlConnectionId string = sqlApiConnection.id
output oracleConnectionId string = oracleApiConnection.id
// Note: Callback URL contains sensitive information - retrieve via Azure Portal or CLI when needed
// output logicAppUrl string = listCallbackURL(resourceId('Microsoft.Logic/workflows/triggers', logicApp.name, 'When_a_new_row_is_added'), '2019-05-01').value
