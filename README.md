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
- Azure Account.
- Azure CLI installed.
- Databricks CLI installed. I have used version 0.18 at the time of development.
- AzCopy installed.
- Sufficient permissions in your Azure account to create resources.

---
## Files and Folders
- Script folder contains the bat files that will deploy the resources.
- Notebooks contain the SQL code located under notebooks folder.
- Job and Cluster Configuration are located under config folder.
- Source Data Files are located under the data folder to test the Databricks Job.
   
## Steps

### 1. **Edit the "Azure and Databricks CLI" file**
- **Open the "Azure and Databricks CLI" file in any text editor and update the parameters as per your values.**
- **Make sure to update the following variables and save the file.**
   - LOCAL_CREATE_TABLES_PATH
   - LOCAL_LOAD_BRONZE_PATH
   - LOCAL_LOAD_SILVER_PATH
   - LOCAL_LOAD_GOLD_PATH
 
### 2. **Run the Databricks Deployment script**
- **Run the "Azure and Databricks CLI" file located in scripts folder from cmd.**

### 3. **Create a Databricks PAT Token**
1. When you are prompted to enter Databricks Host, log in to Your Databricks Workspace in the browser.
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

### 4. **Configure the PAT Token**
Paste your Databricks Host and you will be prompted to enter the token. Paste the token that you copied. Once the script runs you will get to see all the infrasture setup except the Databricks Job.

### 5. **Edit the Azcopy script**
1. Update the parameters in "Upload files to Azure and Run Databricks Job" file. It is located in the scripts folder.
2. The DESTINATION_FILE_NAME should be set to one of the files from the data folder.For example-green_tripdata_2024-02.parquet
3. The LOCAL_JOB_CONFIG_PATH should be set to the path where your Databricks_Job_Config.json is placed. Databricks_Job_Config.json can be found in config folder.
4. Save the file.

### 6. **Run the Azcopy script**
1. Run the "Upload files to Azure and Run Databricks Job" file from cmd.
2. It will prompt for login, open the link mentioned on the screen in the browser and enter the code given on the cmd on the login page.
3. Once the script runs the file will be copied to azure storage container and Databricks job will be created.

