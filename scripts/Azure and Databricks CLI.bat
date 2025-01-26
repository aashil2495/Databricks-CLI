@echo off
setlocal enabledelayedexpansion
:: Set variables
set RESOURCE_GROUP=itm-resourcegroup
set LOCATION=southcentralus
set DATABRICKS_WORKSPACE_NAME=itmdatabricksworkspace
set DATABRICKS_WORKSPACE_SKU=premium
set METASTORE_STORAGE_ACCOUNT=itmmetastorestorage
set METASTORE_CONTAINER=container-metastore
set DATA_STORAGE_ACCOUNT=itmstorage
set RAW_CONTAINER=container-raw
set BRONZE_CONTAINER=container-bronze
set SILVER_CONTAINER=container-silver
set GOLD_CONTAINER=container-gold
set RAW_LAYER_EXTERNAL_LOC_NAME=raw-ext-loc
set BRONZE_LAYER_EXTERNAL_LOC_NAME=bronze-ext-loc
set SILVER_LAYER_EXTERNAL_LOC_NAME=silver-ext-loc
set GOLD_LAYER_EXTERNAL_LOC_NAME=gold-ext-loc
set ACCESS_CONNECTOR_NAME=itm-access-connector
set METASTORE_NAME=southcentralus
set DATABRICKS_STORAGE_CREDENTIAL_NAME=common-storage-cred
set LOCAL_CREATE_TABLES_PATH=C:\Users\aashi\projects\Databricks CLI\notebooks\Create tables.dbc"
set LOCAL_LOAD_BRONZE_PATH="C:\Users\aashi\projects\Databricks CLI\notebooks\Load Bronze Layer.dbc"
set LOCAL_LOAD_SILVER_PATH="C:\Users\aashi\projects\Databricks CLI\notebooks\Load Silver Layer.dbc"
set LOCAL_LOAD_GOLD_PATH="C:\Users\aashi\projects\Databricks CLI\notebooks\Load Gold Layer.dbc"
set DATABRICKS_NOTEBOOK_PATH=/Users/yourname@itmiracle.com
set DATABRICKS_NOTEBOOK_CREATE_TABLES=Create tables
set DATABRICKS_NOTEBOOK_BRONZE=Load Bronze Layer
set DATABRICKS_NOTEBOOK_SILVER=Load Silver Layer
set DATABRICKS_NOTEBOOK_GOLD=Load Gold Layer

call az login

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

:: Create Storage account for data
call az storage account create --name %DATA_STORAGE_ACCOUNT% --resource-group %RESOURCE_GROUP% --location %LOCATION% --sku Standard_LRS --kind StorageV2 --hns true

:: Create container within the storage account for metadata
call az storage container create -n %METASTORE_CONTAINER% --account-name %METASTORE_STORAGE_ACCOUNT% --auth-mode login

:: Create container within the Raw Layer storage account
call az storage container create -n %RAW_CONTAINER% --account-name %DATA_STORAGE_ACCOUNT% --auth-mode login

:: Create container within the Bronze Layer storage account
call az storage container create -n %BRONZE_CONTAINER% --account-name %DATA_STORAGE_ACCOUNT% --auth-mode login

:: Create container within the Silver Layer storage account
call az storage container create -n %SILVER_CONTAINER% --account-name %DATA_STORAGE_ACCOUNT% --auth-mode login

:: Create container within the Gold Layer storage account
call az storage container create -n %GOLD_CONTAINER% --account-name %DATA_STORAGE_ACCOUNT% --auth-mode login

:: Assign "Storage Blob Contributor Role" to access connector on Metastore storage account.
call az role assignment create --assignee %ACCESS_CONNECTOR_PRINCIPAL_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%METASTORE_STORAGE_ACCOUNT%"

:: Assign "Storage Blob Contributor Role" to access connector on Data storage account.
call az role assignment create --assignee %ACCESS_CONNECTOR_PRINCIPAL_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%DATA_STORAGE_ACCOUNT%"

:: Configure the Databricks PAT Token
call databricks configure --token

set METASTORE_ID=

:: Fetch all metastores using Databricks CLI and save to a temporary file
databricks unity-catalog metastores list > metastores.json

:: Read the JSON line by line
for /f "usebackq delims=" %%A in ("metastores.json") do (
    set "LINE=%%A"

    :: Check if the current line contains the name
    echo !LINE! | findstr /i "\"name\": \"%METASTORE_NAME%\"" >nul
    if !errorlevel! == 0 (
        :: If name matches, fetch the following line for the ID
        set "MATCH_FOUND=1"
    )

    :: If a match was found, extract the metastore_id
    if defined MATCH_FOUND (
        echo !LINE! | findstr /i "\"metastore_id\":" >nul
        if !errorlevel! == 0 (
            for /f "tokens=2 delims=:" %%B in ("!LINE!") do (
                set "METASTORE_ID=%%~B"
                set "METASTORE_ID=!METASTORE_ID:~2,-2!" :: Trim quotes and spaces
            )
            set "MATCH_FOUND="
        )
    )
)

:: Clean up the temporary file
del metastores.json

:: Output the result
if defined METASTORE_ID (
    echo Metastore ID for '%METASTORE_NAME%': %METASTORE_ID%
) else (
    echo Metastore with name '%METASTORE_NAME%' not found.
)

:: Unassign the metastore from a workspace you created
call databricks unity-catalog metastores unassign --workspace-id %WORKSPACE_ID% --metastore-id %METASTORE_ID%

:: Delete the metastore
call databricks unity-catalog metastores delete --id %METASTORE_ID% -f

::Create the new metastore
call databricks unity-catalog metastores create --name %METASTORE_NAME% --storage-root abfss://%METASTORE_CONTAINER%@%METASTORE_STORAGE_ACCOUNT%.dfs.core.windows.net/ --region %LOCATION%

set METASTORE_ID=

:: Fetch all metastores using Databricks CLI and save to a temporary file
databricks unity-catalog metastores list > metastores.json

:: Read the JSON line by line
for /f "usebackq delims=" %%A in ("metastores.json") do (
    set "LINE=%%A"

    :: Check if the current line contains the name
    echo !LINE! | findstr /i "\"name\": \"%METASTORE_NAME%\"" >nul
    if !errorlevel! == 0 (
        :: If name matches, fetch the following line for the ID
        set "MATCH_FOUND=1"
    )

    :: If a match was found, extract the metastore_id
    if defined MATCH_FOUND (
        echo !LINE! | findstr /i "\"metastore_id\":" >nul
        if !errorlevel! == 0 (
            for /f "tokens=2 delims=:" %%B in ("!LINE!") do (
                set "METASTORE_ID=%%~B"
                set "METASTORE_ID=!METASTORE_ID:~2,-2!" :: Trim quotes and spaces
            )
            set "MATCH_FOUND="
        )
    )
)

:: Clean up the temporary file
del metastores.json

:: Output the result
if defined METASTORE_ID (
    echo Metastore ID for '%METASTORE_NAME%': %METASTORE_ID%
) else (
    echo Metastore with name '%METASTORE_NAME%' not found.
)

:: Attach new metastore to workspace that you created
call databricks unity-catalog metastores assign --workspace-id %WORKSPACE_ID% --metastore-id %METASTORE_ID%

:: Create Databricks Storage Credential
call databricks unity-catalog storage-credentials create --name %DATABRICKS_STORAGE_CREDENTIAL_NAME% --az-mi-access-connector-id "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Databricks/accessConnectors/%ACCESS_CONNECTOR_NAME%"

:: Create Databricks Raw Layer External Location
call databricks unity-catalog external-locations create --name %RAW_LAYER_EXTERNAL_LOC_NAME% --url "abfss://%RAW_CONTAINER%@%DATA_STORAGE_ACCOUNT%.dfs.core.windows.net/" --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Bronze Layer External Location
call databricks unity-catalog external-locations create --name %BRONZE_LAYER_EXTERNAL_LOC_NAME% --url "abfss://%BRONZE_CONTAINER%@%DATA_STORAGE_ACCOUNT%.dfs.core.windows.net/" --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Silver Layer External Location
call databricks unity-catalog external-locations create --name %SILVER_LAYER_EXTERNAL_LOC_NAME% --url abfss://%SILVER_CONTAINER%@%DATA_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Gold Layer External Location
call databricks unity-catalog external-locations create --name %GOLD_LAYER_EXTERNAL_LOC_NAME% --url abfss://%GOLD_CONTAINER%@%DATA_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks schema
call databricks unity-catalog schemas create --catalog-name main --name bronze

:: Create Databricks schema
call databricks unity-catalog schemas create --catalog-name main --name silver

:: Create Databricks schema
call databricks unity-catalog schemas create --catalog-name main --name gold

::Import Notebooks from local to databricks workspace
call databricks workspace import %LOCAL_CREATE_TABLES_PATH% "%DATABRICKS_NOTEBOOK_PATH%/%DATABRICKS_NOTEBOOK_CREATE_TABLES%" -l PYTHON -f dbc
call databricks workspace import %LOCAL_LOAD_BRONZE_PATH% "%DATABRICKS_NOTEBOOK_PATH%/%DATABRICKS_NOTEBOOK_BRONZE%" -l PYTHON -f dbc
call databricks workspace import %LOCAL_LOAD_SILVER_PATH% "%DATABRICKS_NOTEBOOK_PATH%/%DATABRICKS_NOTEBOOK_SILVER%" -l PYTHON -f dbc
call databricks workspace import %LOCAL_LOAD_GOLD_PATH% "%DATABRICKS_NOTEBOOK_PATH%/%DATABRICKS_NOTEBOOK_GOLD%" -l PYTHON -f dbc

endlocal





