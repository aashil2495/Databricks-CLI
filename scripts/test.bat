@echo off
setlocal enabledelayedexpansion
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

:: Get current workspace ID
for /f "tokens=*" %%i in ('az databricks workspace show --name "%DATABRICKS_WORKSPACE_NAME%" --resource-group "%RESOURCE_GROUP%" --query "workspaceId" -o tsv') do (
    set "WORKSPACE_ID=%%i"
)


:: Store Azure Subscription id in a variable
for /f "delims=" %%i in ('az account show --query "id" -o tsv') do ( set "SUBSCRIPTION_ID=%%i" )

call databricks metastores assign %WORKSPACE_ID% !METASTORE_ID! main

call databricks storage-credentials create  %DATABRICKS_STORAGE_CREDENTIAL_NAME% --azure-managed-identity-access-connector-id "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Databricks/accessConnectors/%ACCESS_CONNECTOR_NAME%"

