# Azure Databricks Setup

This README provides step-by-step instructions to set up resources in Azure and configure Databricks for managing data workflows.
The setup includes:
- Resource Group
- Databricks Workspace
- Storage Accounts
- Containers
- Databricks PAT Token
- Metastore
- Access Connector
- Attaching Metastore to Worksapce
- Adding role to Access Connector
- External Storage Credential
- External Storage Location
- Catalog
- Schemas
- Copying files using azcopy
- Create Databricks Job
- Running the Job
- Creating Databricks Cluster

---

## Prerequisites
1. Azure CLI installed and configured.
2. Databricks CLI installed.
3. AzCopy installed.
4. Sufficient permissions in your Azure account to create resources.

---
## Files
1. Databricks_CLIV2 contains the code
2. Noteboo
## Steps

### 1. **Login to Azure Portal**
```bash
az login
```

### 2. **Create a Resource Group**
```bash
az group create --name ashil-resourcegroup --location southcentralus
```
Replace `ashil-resourcegroup` with your desired name.

### 3. **Create a Databricks Workspace**
```bash
az databricks workspace create --resource-group ashil-resourcegroup --name ashilDatabricksWorkspace --location southcentralus --sku premium
```
Replace `ashilDatabricksWorkspace` with your desired name.

### 4. **Create a Storage Account**
```bash
az storage account create --name ashilstorage --resource-group ashil-resourcegroup --location southcentralus --sku Standard_LRS --kind StorageV2 --hns true
```
Replace `ashilstorage` with your desired name.

### 5. **Create a Container in the Storage Account**
```bash
az storage container create -n metastore-container --account-name ashilstorage --auth-mode login
```
Replace `metastore-container` with your desired name.

### 6. **Create a Storage Account**
```bash
az storage account create --name ashilstoragedatastore --resource-group ashil-resourcegroup --location southcentralus --sku Standard_LRS --kind StorageV2 --hns true
```
Replace `ashilstoragedatastore` with your desired name.

### 7. **Create a Raw, Bronze, Silver and Gold Container in the Storage Account**
```bash
az storage container create -n raw --account-name ashilstoragedatastore --auth-mode login
az storage container create -n bronze --account-name ashilstoragedatastore --auth-mode login
az storage container create -n silver --account-name ashilstoragedatastore --auth-mode login
az storage container create -n gold --account-name ashilstoragedatastore --auth-mode login
```
Replace `ashilstoragedatastore` with your desired name.

### 8. **List Containers in the Storage Account**
```bash
az storage container list \
    --account-name ashilstoragedatastore \
    --auth-mode login \
    --query "[].name" -o table
```
Replace `ashilstoragedatastore` with your desired name.

### 9. **Create the Databricks PAT Token**
1. Log in to Your Databricks Workspace
Open your Databricks workspace in a browser.
The URL typically looks like: https://<your-databricks-instance>.cloud.databricks.com.

2. Navigate to User Settings
In the top-right corner, click your profile icon.
Select User Settings from the dropdown menu.

3. Go to the Access Tokens Tab
In the User Settings page, click on the Access Tokens tab.
Click on the Generate New Token button.

4. Configure the Token
Comment (Optional): Provide a description or label for the token to identify its purpose.
Lifetime (Optional): Set an expiration time for the token, or leave it blank for the default (which varies by workspace).

5. Generate the Token
Click the Generate button.
A new token will be displayed.
Important: Copy the token immediately. You will not be able to view it again after this step.

### 10. **Configure the Databricks PAT Token**
```bash
databricks configure --token
```

### 11. **Create unity catalog metastore in Databricks account**
```bash
databricks unity-catalog metastores create --name southcentralus --storage-root abfss://metastore-container@ashilstorage.dfs.core.windows.net/ --region southcentralus
```
Replace the `southcentralus`,`metastore-container` and `ashilstorage` with your desired name.

### 12. **Assign metastore to workspace**
```bash
databricks unity-catalog metastores assign --workspace-id 2744189980357297 --metastore-id d590c7f3-5713-43f6-886e-019e9cce2aca --default-catalog-name main
```
Replace the `2744189980357297`, `d590c7f3-5713-43f6-886e-019e9cce2aca` and `main` with your values.

### 13. **Create Databricks Access Connector**
```bash
az databricks access-connector create --resource-group ashil-resourcegroup --name ashil-access-connector --location southcentralus --identity-type SystemAssigned
```
Replace `ashil-resourcegroup`, `ashil-access-connector` with your desired names.

### 14. **List Databricks Access Connector**
```bash
az databricks access-connector show --resource-group ashil-resourcegroup --name ashil-access-connector --query "identity.principalId" -o tsv
```
Replace `ashil-resourcegroup`, `ashil-access-connector` with your desired names.

### 15. **List Azure Subscriptions**
```bash
az account list --output table
```

### 16. **List Storage Accounts**
```bash
az storage account list --output table
```

### 17. **Assign Role to Managed Identity (Access Connector)**
```bash
az role assignment create --assignee 82eb651a-a93c-4bb9-970b-c61f48d6e346 --role "Storage Blob Data Contributor" --scope "/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/ashil-resourcegroup/providers/Microsoft.Storage/storageAccounts/ashilstorage"
az role assignment create --assignee 82eb651a-a93c-4bb9-970b-c61f48d6e346 --role "Storage Blob Data Contributor" --scope "/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/ashil-resourcegroup/providers/Microsoft.Storage/storageAccounts/ashilstoragedatastore"
```
Replace `82eb651a-a93c-4bb9-970b-c61f48d6e346`, `/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/ashil-resourcegroup/providers/Microsoft.Storage/storageAccounts/ashilstorage`,  `/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/ashil-resourcegroup/providers/Microsoft.Storage/storageAccounts/ashilstorage` with your desored values.

### 18. **List Access Connectors**
```bash
az databricks access-connector list --output table
```

### 19. **Create Storage Credentials**
```bash
databricks unity-catalog storage-credentials create --name common-storage-cred --az-mi-access-connector-id "/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/ashil-resourcegroup/providers/Microsoft.Databricks/accessConnectors/ashil-access-connector"
```
Replace `common-storage-cred`, `/subscriptions/d066615d-e286-4bf1-92e7-7df087f1f4d0/resourceGroups/ashil-resourcegroup/providers/Microsoft.Databricks/accessConnectors/ashil-access-connector` with your desired values.

### 20. **Create Raw, Bronze, Silver and Gold External Location**
```bash
databricks unity-catalog external-locations create --name raw-loc --url abfss://raw@ashilstoragedatastore.dfs.core.windows.net/ --storage-credential-name common-storage-cred
databricks unity-catalog external-locations create --name bronze-loc --url abfss://bronze@ashilstoragedatastore.dfs.core.windows.net/ --storage-credential-name common-storage-cred
databricks unity-catalog external-locations create --name silver-loc --url abfss://silver@ashilstoragedatastore.dfs.core.windows.net/ --storage-credential-name common-storage-cred
databricks unity-catalog external-locations create --name gold-loc --url abfss://gold@ashilstoragedatastore.dfs.core.windows.net/ --storage-credential-name common-storage-cred
```
Replace `abfss://raw@ashilstoragedatastore.dfs.core.windows.net/`, `abfss://bronze@ashilstoragedatastore.dfs.core.windows.net/`, `abfss://silver@ashilstoragedatastore.dfs.core.windows.net/`, `abfss://gold@ashilstoragedatastore.dfs.core.windows.net/`, `common-storage-cred` with your desired values.

### 21. **Create Unity Catalog Schemas**
#### Create "bronze" Schema
```bash
databricks unity-catalog schemas create --catalog-name main --name bronze
```

#### Create "silver" Schema
```bash
databricks unity-catalog schemas create --catalog-name main --name silver
```

#### Create "gold" Schema
```bash
databricks unity-catalog schemas create --catalog-name main --name gold
```

### 22. **Login with azcopy**
```bash
azcopy login
```
Follow the on-screen instructions and login to Azure. Open the URL shown on the screen in a browser and paste the code in the prompt to login.

### 23. **Copy single file from local path to raw container on storage**
```bash
azcopy copy "C:\Users\aashi\projects\synthea\synthea\output\csv\2024_12_21T17_44_38Z\patients.csv" "https://ashilstoragedatastore.blob.core.windows.net/raw/patients.csv"
```
Replace `C:\Users\aashi\projects\synthea\synthea\output\csv\2024_12_21T17_44_38Z\patients.csv` and `https://ashilstoragedatastore.blob.core.windows.net/raw/patients.csv` with your desired paths.
You can run this command multiple times to test the pipeline.

### 24. **Import Notebook from Notebooks folder to your Databricks Workspace.**
1. Create a Notebook by selecting (+ New) from sidebar and selecting Notebook.
2. Click File and select Import...
3. Import your Notebooks from Notebooks folder in the repo.  

### 25. **Create a Databricks Job using UI to get Job Configuration**
1. Access the Jobs Page  
    1.1. Log in to your Databricks workspace.  
    1.2. In the left sidebar, click on **Workflows** (or **Jobs**, depending on your workspace version).  

2. Create a New Job  
    2.1. Click the **Create Job** button.  
    2.2. Fill in the required fields:  
        2.2.1. **Job Name:** Provide a name for the job.  
        2.2.2. **Task Configuration:**  
            - **Task Name:** Name your task.  
            - **Type:** Choose the task type (e.g., Notebook, JAR, Python Script).  
            - **Cluster:** Choose an existing cluster or create a new one by selecting **New Cluster** and configuring its settings.  
            - **Notebook Path:** If using a notebook, provide its path.  
        2.2.3. **Advanced Settings (Optional):** Configure dependencies, email notifications, and retry policies.  
    2.3. Save the job by clicking **Save task**.  
    2.4. Click on the kebab (3 dots) icon on the top-right corner next to **Run now**.  
    2.5. Select **View JSON** option, click on the **Create** tab, and copy the configuration.  
    2.6. Save the configuration to a file in JSON format.
   
### 26. **Create a Databricks Job**
```bash
databricks jobs create --json-file C:\Users\aashi\projects\Databricks_Job_Config.json
```
Replace `C:\Users\aashi\projects\Databricks_Job_Config.json` with your desired path.

### 27. **Run the Databricks Job**
```bash
databricks jobs run-now --job-id 189025494907676
```
Replace `189025494907676` with your job id.

### 28. **Create Databricks Cluster using UI to get Cluster Configuration**
- **Access the Compute Page**
  - Log in to your Databricks workspace.
  - In the left sidebar, click on **Compute**.

- **Create a New Cluster**
  - Click the **Create Compute** button.
  - Fill in the required fields:
    - **Cluster Name:** Provide a unique name for the cluster.
    - **Cluster Policy:** Provide a unique name for the cluster.
    - **Cluster Mode:** Select either:
      - **Multi Node:** For a single machine cluster.
      - **Single Node:** For shared workloads.
    - **Access Mode:** Select either:
    - **Databricks Runtime Version:** Choose the appropriate runtime version based on your workload requirements (e.g., Scala, Spark, ML).
    - **Worker Configuration:**
      - **Worker Type:** Select the instance type (e.g., Standard_DS3_v2).
      - **Workers:** Specify the number of worker nodes for the cluster.
      - **Driver Type:** Select the instance type for the driver node.
    - **Advanced Options (Optional):**
      - Set Spark configurations, environment variables, or custom logging.
      - Configure autoscaling and termination policies.

- **Save and Start the Cluster**
  - Click **Create Compute** to save your configuration and start the cluster.
  - The cluster will appear in the **Compute** page with its current status (e.g., starting, running, terminated).

- **Copy the JSON Configuration of the Created Cluster**
  - Navigate to the **Compute** page.
  - Locate your created cluster and click on its name to open the cluster details.
  - Click on the **Advanced Options** tab or look for the **JSON** section (depending on your Databricks version).
  - Click on the **Edit** or **View JSON** option (a pencil or JSON icon is typically available), select **Create**
  - Copy the JSON configuration of the cluster and save it to a file in JSON format for reference or reuse.

- **Optional: Edit or Terminate the Cluster**
  - To edit a cluster, click on the cluster name and modify the configuration.
  - To terminate a cluster, click the **Terminate** button on the cluster details page.

### 29. **Create Databricks Cluster**
```bash
databricks clusters create --json-file C:\Users\aashi\projects\Databricks_Cluster_Config.json
```
Replace `C:\Users\aashi\projects\Databricks_Cluster_Config.json` with your desired path`

---

## Notes
- Replace placeholder values with your specific resource names and IDs.
- Ensure appropriate permissions are granted for all resources.
