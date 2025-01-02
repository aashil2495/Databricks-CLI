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

### 5. **Create a Container in the Storage Account**
```bash
az storage container create \
    --account-name itmmystorageaccountcli \
    --name container
```

### 6. **List Containers in the Storage Account**
```bash
az storage container list \
    --account-name itmmystorageaccountcli \
    --
