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

:: Get default workspace metastore details
for /f "tokens=*" %%i in ('databricks unity-catalog metastores get-assignment ^| findstr "metastore_id"') do (
    set "CURRENT_METASTORE_ID=%%i"
)

:: Fetch Metastore ID
for /f "tokens=2 delims=:," %%j in ("%CURRENT_METASTORE_ID%") do (
    set "CURRENT_METASTORE_ID=%%j"
)

:: Remove double quotes from the ID
set CURRENT_METASTORE_ID=%CURRENT_METASTORE_ID:"=%
set CURRENT_METASTORE_ID=%CURRENT_METASTORE_ID: =%

:: Delete catalogs
call databricks unity-catalog catalogs delete --name system -p
call databricks unity-catalog catalogs delete --name samples -p
call databricks unity-catalog catalogs delete --name %DATABRICKS_WORKSPACE_NAME% -p

:: Unassign the metastore
call databricks unity-catalog metastores unassign --workspace-id %WORKSPACE_ID% --metastore-id %CURRENT_METASTORE_ID%

:: Delete the default metastore
call databricks unity-catalog metastores delete --id %CURRENT_METASTORE_ID% --force

:: Create a new metastore
call databricks unity-catalog metastores create --name %METASTORE_NAME% --storage-root abfss://%METASTORE_CONTAINER%@%METASTORE_STORAGE_ACCOUNT%.dfs.core.windows.net/ --region %LOCATION%

:: Get Metastore List and store the output in a temporary file
call databricks unity-catalog metastores list > temp.json

:: Loop through the file and find the correct metastore name first
set "found="
for /f "delims=" %%i in (temp.json) do (
    set "line=%%i"
    echo !line! | findstr /i /c:"\"name\": \"!METASTORE_NAME!\"" >nul
    if not errorlevel 1 (
        set "found=1"
    )
    if defined found (
        echo !line! | findstr /i /c:"\"metastore_id\": " >nul
        if not errorlevel 1 (
            for /f "tokens=2 delims=: " %%j in ("!line!") do (
                set "METASTORE_ID=%%j"
            )
            goto found_metastore_id
        )
    )
)

:found_metastore_id

:: Clean up the JSON formatting
if defined METASTORE_ID (
    set METASTORE_ID=!METASTORE_ID:~1,-2!
    echo !METASTORE_ID!
) else (
    echo Metastore ID not found.
)

:: Clean up
del temp.json

:: Assign metastore to workspace
call databricks unity-catalog metastores assign --workspace-id %WORKSPACE_ID% --metastore-id !METASTORE_ID! --default-catalog-name main

:: Create Databricks Storage Credential
call databricks unity-catalog storage-credentials create --name %DATABRICKS_STORAGE_CREDENTIAL_NAME% --az-mi-access-connector-id "/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Databricks/accessConnectors/%ACCESS_CONNECTOR_NAME%"

:: Create Databricks Raw Layer External Location
call databricks unity-catalog external-locations create --name %RAW_LAYER_EXTERNAL_LOC_NAME% --url abfss://%RAW_STORAGE_ACCOUNT_CONTAINER%@%RAW_LAYER_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Bronze Layer External Location
call databricks unity-catalog external-locations create --name %BRONZE_LAYER_EXTERNAL_LOC_NAME% --url abfss://%BRONZE_STORAGE_ACCOUNT_CONTAINER%@%BRONZE_LAYER_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Silver Layer External Location
call databricks unity-catalog external-locations create --name %SILVER_LAYER_EXTERNAL_LOC_NAME% --url abfss://%SILVER_STORAGE_ACCOUNT_CONTAINER%@%SILVER_LAYER_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%

:: Create Databricks Raw Layer External Location
call databricks unity-catalog external-locations create --name %GOLD_LAYER_EXTERNAL_LOC_NAME% --url abfss://%GOLD_STORAGE_ACCOUNT_CONTAINER%@%GOLD_LAYER_STORAGE_ACCOUNT%.dfs.core.windows.net/ --storage-credential-name %DATABRICKS_STORAGE_CREDENTIAL_NAME%


endlocal





