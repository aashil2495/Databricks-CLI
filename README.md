# Azure Databricks Setup

This README provides step-by-step instructions to set up resources in Azure and configure Databricks for managing data workflows. The setup includes creating a resource group, Databricks workspace, storage accounts, Unity Catalog, and schemas.

---

## Prerequisites
1. Azure CLI installed and configured.
2. Databricks CLI installed.
3. Sufficient permissions in your Azure account to create resources.

---

## Steps

### 1. **Login to Azure Portal**
```bash
az login
```

### 2. **Create a Resource Group**
```bash
az group create --name myResourceGroup --location southcentralus
```
Replace `myResourceGroup` with your desired name.

### 3. **Create a Databricks Workspace**
```bash
az databricks workspace create \
    --resource-group myResourceGroup \
    --name myDatabricksWorkspace \
    --location southcentralus \
    --sku premium
```
Replace `myDatabricksWorkspace` with your desired name.

### 4. **Create a Storage Account**
```bash
az storage account create \
    --name itmmystorageaccountgen2 \
    --resource-group myResourceGroup \
    --location southcentralus \
    --sku Standard_LRS \
    --kind StorageV2 \
    --hns true
```
Replace `itmmystorageaccountgen2` with your desired name.

### 5. **Create a Container in the Storage Account**
```bash
az storage container create \
    --account-name itmmystorageaccountcli \
    --name container
```
Replace `container` with your desired name.

### 6. **List Containers in the Storage Account**
```bash
az storage container list \
    --account-name itmmystorageaccountcli \
    --auth-mode login \
    --query "[].name" -o table
```

### 7. **Configure the Databricks PAT Token**
```bash
databricks configure --token
```

### 8. **Create unity catalog metastore in Databricks account**
```bash
databricks unity-catalog metastores create \
   --name metastoresouthcentralus \
   --storage-root abfss://container@itmmystorageaccountcli.dfs.core.windows.net/ \
   --region southcentralus
```

### 9. **Assign metastore to workspace**
```bash
databricks unity-catalog metastores assign \
   --workspace-id 2802728894264871 \
   --metastore-id a6c116d8-6ec1-460a-98d1-6f0f62e25695 \
   --default-catalog-name main
```

### 10. **Create Databricks Access Connector**
```bash
az databricks access-connector create \
    --resource-group myResourceGroup \
    --name my-access-connector \
    --location southcentralus \
    --identity-type SystemAssigned
```

### 11. **List Databricks Access Connector**
```bash
az databricks access-connector show \
    --resource-group myResourceGroup \
    --name my-access-connector \
    --query "identity.principalId" -o tsv
```

### 12. **List Azure Subscriptions**
```bash
az account list --output table
```

### 13. **List Storage Accounts**
```bash
az storage account list --output table
```

### 14. **Assign Role to Managed Identity (Access Connector)**
```bash
az role assignment create \
    --assignee ea0bb2f9-762f-496c-a5ce-8d33f4dd1790 \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/myResourceGroup/providers/Microsoft.Storage/storageAccounts/itmmystorageaccountcli"
```

### 15. **List Access Connectors**
```bash
az databricks access-connector list --output json
```

### 16. **Create Storage Credentials**
```bash
databricks unity-catalog storage-credentials create \
    --name external-loc \
    --az-mi-access-connector-id "/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/myResourceGroup/providers/Microsoft.Databricks/accessConnectors/my-access-connector"
```

### 17. **Create External Location**
```bash
databricks unity-catalog external-locations create \
    --name my_external_location \
    --url abfss://container@itmmystorageaccountcli.dfs.core.windows.net/ \
    --storage-credential-name external-loc
```

### 18. **Assign Role to Managed Identity on Another Storage Account**
```bash
az role assignment create \
    --assignee ea0bb2f9-762f-496c-a5ce-8d33f4dd1790 \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/myResourceGroup/providers/Microsoft.Storage/storageAccounts/itmdatastore"
```

### 19. **Create External Location for Another Storage Account**
```bash
databricks unity-catalog external-locations create \
    --name itmdatastore-bronze \
    --url abfss://bronze@itmdatastore.dfs.core.windows.net/ \
    --storage-credential-name external-loc
```

### 20. **Create Unity Catalog Schemas**
#### Create "bronze" Schema
```bash
databricks unity-catalog schemas create \
    --catalog-name main \
    --name bronze
```

#### Create "silver" Schema
```bash
databricks unity-catalog schemas create \
    --catalog-name main \
    --name silver
```

#### Create "gold" Schema
```bash
databricks unity-catalog schemas create \
    --catalog-name main \
    --name gold
```

---

## Notes
- Replace placeholder values with your specific resource names and IDs.
- Ensure appropriate permissions are granted for all resources.
