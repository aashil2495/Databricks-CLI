# Databricks-CLI
This README provides a summary of the CLI commands to perform various tasks in Databricks and Azure, along with explanations of each command's purpose.

Goal

To streamline Databricks and Azure resource management using CLI commands, including creating resources, configuring Unity Catalog, uploading data, and managing tables.

Prerequisites

Azure CLI installed and authenticated:

az login

Databricks CLI installed and configured:

databricks configure --token

CLI Commands and Descriptions

1. Login to Azure Portal

Authenticate with your Azure account.

az login

2. Create a Resource Group

Create a new Azure resource group to organize resources.

az group create --name myResourceGroup --location southcentralus

3. Create a Databricks Workspace

Create a premium Databricks workspace in Azure.

az databricks workspace create \
    --resource-group myResourceGroup \
    --name myDatabricksWorkspace \
    --location southcentralus \
    --sku premium

4. Create a Storage Account

Create an Azure Storage account with hierarchical namespace enabled.

az storage account create \
    --name itmmystorageaccountgen2 \
    --resource-group myResourceGroup \
    --location southcentralus \
    --sku Standard_LRS \
    --kind StorageV2 \
    --hns true

5. Create a Storage Container

Create a container in the storage account.

az storage container create \
    --account-name itmmystorageaccountgen2 \
    --name itmmystorageaccountcli

6. List Storage Containers

List the containers in a storage account.

az storage container list \
    --account-name itmmystorageaccountgen2 \
    --auth-mode login \
    --query "[].name" -o table

7. Configure Databricks PAT Token

Configure the Databricks CLI with a Personal Access Token (PAT).

databricks configure --token

8. Create Unity Catalog Metastore

Create a Unity Catalog metastore in Databricks.

databricks unity-catalog metastores create \
    --name metastoresouthcentralus \
    --storage-root abfss://container@itmmystorageaccountcli.dfs.core.windows.net/ \
    --region southcentralus

9. Assign Metastore to Workspace

Assign the Unity Catalog metastore to a Databricks workspace.

databricks unity-catalog metastores assign \
    --workspace-id 2802728894264871 \
    --metastore-id a6c116d8-6ec1-460a-98d1-6f0f62e25695 \
    --default-catalog-name main

10. Create Databricks Access Connector

Create an access connector for Azure resources.

az databricks access-connector create \
    --resource-group myResourceGroup \
    --name my-access-connector \
    --location southcentralus \
    --identity-type SystemAssigned

11. List Databricks Access Connectors

Retrieve a list of Databricks access connectors.

az databricks access-connector list --output json

12. Assign Role to Managed Identity

Grant the managed identity (access connector) permission to access the storage account.

az role assignment create \
    --assignee <principal_id> \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/<subscription_id>/resourceGroups/myResourceGroup/providers/Microsoft.Storage/storageAccounts/itmmystorageaccountgen2"

13. Create Storage Credentials

Create Unity Catalog storage credentials for accessing the external location.

databricks unity-catalog storage-credentials create \
    --name external-loc \
    --az-mi-access-connector-id "/subscriptions/<subscription_id>/resourceGroups/myResourceGroup/providers/Microsoft.Databricks/accessConnectors/my-access-connector"

14. Create External Location

Create an external location in Unity Catalog.

databricks unity-catalog external-locations create \
    --name my_external_location \
    --url abfss://container@itmmystorageaccountcli.dfs.core.windows.net/ \
    --storage-credential-name external-loc

15. Create a Schema with External Location

Create a schema in Unity Catalog and link it to the external location.

databricks unity-catalog schemas create \
    --name my_schema \
    --catalog-name main \
    --storage-root abfss://container@itmmystorageaccountcli.dfs.core.windows.net/ \
    --storage-credential-name external-loc

16. Create an External Table

Create an external table using Unity Catalog.

databricks unity-catalog tables create \
    --name my_table \
    --catalog-name main \
    --schema-name my_schema \
    --table-type EXTERNAL \
    --storage-location abfss://container@itmmystorageaccountcli.dfs.core.windows.net/<path_to_table> \
    --columns '[{"name":"id","type":"INT"},{"name":"name","type":"STRING"}]'

Notes

Replace placeholder values (e.g., <container>, <storage_account>, <principal_id>, <subscription_id>, etc.) with actual values.

Ensure proper permissions are assigned to Databricks and Azure resources to avoid access issues.

Serverless and Unity Catalog features may depend on your Databricks subscription and region availability.
