@echo off
setlocal enabledelayedexpansion
:: Set variables
set RESOURCE_GROUP=ashil-resourcegroup
set LOCATION=southcentralus
set DATABRICKS_WORKSPACE_NAME=ashildatabricksworkspace
set DATABRICKS_WORKSPACE_SKU=premium
set METASTORE_STORAGE_ACCOUNT=ashilmetastorestorage
set METASTORE_CONTAINER=container-metastore
set DATA_STORAGE_ACCOUNT=ashilstorage
set RAW_CONTAINER=container-raw
set BRONZE_CONTAINER=container-bronze
set SILVER_CONTAINER=container-silver
set GOLD_CONTAINER=container-gold
set RAW_LAYER_EXTERNAL_LOC_NAME=raw-ext-loc
set BRONZE_LAYER_EXTERNAL_LOC_NAME=bronze-ext-loc
set SILVER_LAYER_EXTERNAL_LOC_NAME=silver-ext-loc
set GOLD_LAYER_EXTERNAL_LOC_NAME=gold-ext-loc
set ACCESS_CONNECTOR_NAME=ashil-access-connector
set METASTORE_NAME=southcentralus
set DATABRICKS_STORAGE_CREDENTIAL_NAME=common-storage-cred



:: Store Azure Subscription id in a variable
for /f "delims=" %%i in ('az account show --query "id" -o tsv') do ( set "SUBSCRIPTION_ID=%%i" )


:: Get current workspace ID
for /f "tokens=*" %%i in ('az databricks workspace show --name "%DATABRICKS_WORKSPACE_NAME%" --resource-group "%RESOURCE_GROUP%" --query "workspaceId" -o tsv') do (
    set "WORKSPACE_ID=%%i"
)


call databricks unity-catalog external-locations create --name %RAW_LAYER_EXTERNAL_LOC_NAME% --url abfss://%RAW_CONTAINER%@%DATA_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%
