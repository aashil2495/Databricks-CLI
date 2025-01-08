@echo off
setlocal enabledelayedexpansion
:: Set variables
set RESOURCE_GROUP=ashil-resourcegroup
set LOCATION=southcentralus
set DATABRICKS_WORKSPACE_NAME=ashildatabricksworkspace
set DATABRICKS_WORKSPACE_SKU=premium
set METASTORE_STORAGE_ACCOUNT=ashilmetastorestorage
set METASTORE_CONTAINER=container-metastore
set RAW_LAYER_STORAGE_ACCOUNT=ashilraw
set BRONZE_LAYER_STORAGE_ACCOUNT=ashilbronze
set SILVER_LAYER_STORAGE_ACCOUNT=ashilsilver
set GOLD_LAYER_STORAGE_ACCOUNT=ashilgold
set RAW_STORAGE_ACCOUNT_CONTAINER=container-raw
set BRONZE_STORAGE_ACCOUNT_CONTAINER=container-bronze
set SILVER_STORAGE_ACCOUNT_CONTAINER=container-silver
set GOLD_STORAGE_ACCOUNT_CONTAINER=container-gold
set RAW_LAYER_EXTERNAL_LOC_NAME=raw-ext-loc
set BRONZE_LAYER_EXTERNAL_LOC_NAME=bronze-ext-loc
set SILVER_LAYER_EXTERNAL_LOC_NAME=silver-ext-loc
set GOLD_LAYER_EXTERNAL_LOC_NAME=gold-ext-loc
set ACCESS_CONNECTOR_NAME=ashil-access-connector
set METASTORE_NAME=southcentralus

:: Store Azure Subscription id in a variable
for /f "delims=" %%i in ('az account show --query "id" -o tsv') do ( set "SUBSCRIPTION_ID=%%i" )

:: Create Resource Group
call az group create --name %RESOURCE_GROUP% --location %LOCATION%

:: Create Access Connector(Managed Identity) for Databricks Workspace
call az databricks access-connector create --resource-group %RESOURCE_GROUP% --name %ACCESS_CONNECTOR_NAME% --location %LOCATION% --identity-type SystemAssigned

:: Create Databricks Access Connector and store it's id in a variable
for /f "tokens=*" %%i in ('az databricks access-connector show --resource-group "%RESOURCE_GROUP%" --name "%ACCESS_CONNECTOR_NAME%" --query "identity.principalId" -o tsv') do (
    set "ACCESS_CONNECTOR_PRINCIPAL_ID=%%i")

:: Create Datarbicks Workspace
call az databricks workspace create --resource-group %RESOURCE_GROUP% --name %DATABRICKS_WORKSPACE_NAME% --location %LOCATION% --sku %DATABRICKS_WORKSPACE_SKU%

:: Get current workspace ID
for /f "tokens=*" %%i in ('az databricks workspace show --name "%DATABRICKS_WORKSPACE_NAME%" --resource-group "%RESOURCE_GROUP%" --query "workspaceId" -o tsv') do (
    set "WORKSPACE_ID=%%i"
)

:: Create storage account for metadata
call az storage account create --name %METASTORE_STORAGE_ACCOUNT% --resource-group %RESOURCE_GROUP% --location %LOCATION% --sku Standard_LRS --kind StorageV2 --hns true

:: Create Storage account for Raw Layer
call az storage account create --name %RAW_LAYER_STORAGE_ACCOUNT% --resource-group %RESOURCE_GROUP% --location %LOCATION% --sku Standard_LRS --kind StorageV2 --hns true

:: Create Storage account for Bronze Layer
call az storage account create --name %BRONZE_LAYER_STORAGE_ACCOUNT% --resource-group %RESOURCE_GROUP% --location %LOCATION% --sku Standard_LRS --kind StorageV2 --hns true

:: Create Storage account for Silver Layer
call az storage account create --name %SILVER_LAYER_STORAGE_ACCOUNT% --resource-group %RESOURCE_GROUP% --location %LOCATION% --sku Standard_LRS --kind StorageV2 --hns true

:: Create Storage account for Gold Layer
call az storage account create --name %GOLD_LAYER_STORAGE_ACCOUNT% --resource-group %RESOURCE_GROUP% --location %LOCATION% --sku Standard_LRS --kind StorageV2 --hns true

:: Create container within the storage account for metadata
call az storage container create -n %METASTORE_CONTAINER% --account-name %METASTORE_STORAGE_ACCOUNT% --auth-mode login

:: Create container within the Raw Layer storage account
call az storage container create -n %RAW_STORAGE_ACCOUNT_CONTAINER% --account-name %RAW_LAYER_STORAGE_ACCOUNT% --auth-mode login

:: Create container within the Bronze Layer storage account
call az storage container create -n %BRONZE_STORAGE_ACCOUNT_CONTAINER% --account-name %BRONZE_LAYER_STORAGE_ACCOUNT% --auth-mode login

:: Create container within the Silver Layer storage account
call az storage container create -n %SILVER_STORAGE_ACCOUNT_CONTAINER% --account-name %SILVER_LAYER_STORAGE_ACCOUNT% --auth-mode login

:: Create container within the Gold Layer storage account
call az storage container create -n %GOLD_STORAGE_ACCOUNT_CONTAINER% --account-name %GOLD_LAYER_STORAGE_ACCOUNT% --auth-mode login

:: Assign "Storage Blob Contributor Role" to access connector on Metastore storage account.
call az role assignment create --assignee %ACCESS_CONNECTOR_PRINCIPAL_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%METASTORE_STORAGE_ACCOUNT%"

:: Assign "Storage Blob Contributor Role" to access connector on Raw Layer storage account.
call az role assignment create --assignee %ACCESS_CONNECTOR_PRINCIPAL_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%RAW_LAYER_STORAGE_ACCOUNT%"

:: Assign "Storage Blob Contributor Role" to access connector on Bronze Layer storage account.
call az role assignment create --assignee %ACCESS_CONNECTOR_PRINCIPAL_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%BRONZE_LAYER_STORAGE_ACCOUNT%"

:: Assign "Storage Blob Contributor Role" to access connector on Silver Layer storage account.
call az role assignment create --assignee %ACCESS_CONNECTOR_PRINCIPAL_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%SILVER_LAYER_STORAGE_ACCOUNT%"

:: Assign "Storage Blob Contributor Role" to access connector on Gold Layer storage account.
call az role assignment create --assignee %ACCESS_CONNECTOR_PRINCIPAL_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%GOLD_LAYER_STORAGE_ACCOUNT%"

:: Configure the Databricks PAT Token
databricks configure --token

:: Get the output of the Databricks metastores command and store it in a temporary file
databricks metastores current > temp_output.json

:: Use findstr to get the line containing "metastore_id", and extract the value
for /f "tokens=2 delims=:," %%a in ('findstr /i "metastore_id" temp_output.json') do (
    set CURRENT_METASTORE_ID=%%a
)

:: Remove extra spaces or quotes from the METASTORE_ID
set CURRENT_METASTORE_ID=%CURRENT_METASTORE_ID: =%
set CURRENT_METASTORE_ID=%CURRENT_METASTORE_ID:~1,-1%

:: Display the extracted METASTORE_ID
call echo Metastore ID: %CURRENT_METASTORE_ID%

:: Clean up temporary file
del temp_output.json

:: Delete catalogs
call databricks catalogs delete --name system -p
call databricks catalogs delete --name samples -p
call databricks catalogs delete --name %DATABRICKS_WORKSPACE_NAME% -p

:: Unassign the metastore
call databricks metastores unassign --workspace-id %WORKSPACE_ID% --metastore-id %CURRENT_METASTORE_ID%

:: Delete the default metastore
call databricks metastores delete --id %CURRENT_METASTORE_ID% --force

:: Create a new metastore
call databricks metastores create --name %METASTORE_NAME% --storage-root abfss://%METASTORE_CONTAINER%@%METASTORE_STORAGE_ACCOUNT%.dfs.core.windows.net/ --region %LOCATION%

:: Run the Databricks metastores list command and store the output in a temporary file
databricks metastores list > temp_output.txt

:: Initialize the variable to store the ID
set METASTORE_ID=

:: Loop through each line of the output to find the matching region
for /f "tokens=1,3" %%a in ('findstr /i "southcentralus" temp_output.txt') do (
    set METASTORE_ID=%%a
)

:: Display the extracted METASTORE_ID
echo Metastore ID: %METASTORE_ID%

:: Clean up temporary file
del temp_output.txt

:: Assign metastore to workspace
call databricks metastores assign --workspace-id %WORKSPACE_ID% --metastore-id !METASTORE_ID! --default-catalog-name main

:: Create Databricks Storage Credential
call databricks storage-credentials create --name %DATABRICKS_STORAGE_CREDENTIAL_NAME% --az-mi-access-connector-id "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Databricks/accessConnectors/%ACCESS_CONNECTOR_NAME%"

:: Create Databricks Raw Layer External Location
call databricks external-locations create --name %RAW_LAYER_EXTERNAL_LOC_NAME% --url abfss://%RAW_STORAGE_ACCOUNT_CONTAINER%@%RAW_LAYER_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Bronze Layer External Location
call databricks external-locations create --name %BRONZE_LAYER_EXTERNAL_LOC_NAME% --url abfss://%BRONZE_STORAGE_ACCOUNT_CONTAINER%@%BRONZE_LAYER_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Silver Layer External Location
call databricks unity-catalog external-locations create --name %SILVER_LAYER_EXTERNAL_LOC_NAME% --url abfss://%SILVER_STORAGE_ACCOUNT_CONTAINER%@%SILVER_LAYER_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Gold Layer External Location
call databricks unity-catalog external-locations create --name %GOLD_LAYER_EXTERNAL_LOC_NAME% --url abfss://%GOLD_STORAGE_ACCOUNT_CONTAINER%@%GOLD_LAYER_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

call databricks unity-catalog schems
endlocal





