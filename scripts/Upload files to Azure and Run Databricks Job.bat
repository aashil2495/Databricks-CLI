@echo off
:: Set Variables
::Enter the full path to file
set LOCAL_PATH_TO_FILE=yourpath\green_tripdata_2024-02.parquet
set DESTINATION_STORAGE_ACCOUNT_NAME=itmstorage
set DESTINATION_STORAGE_CONTAINER_NAME=container-raw
set DESTINATION_FILE_NAME=green_tripdata_2024-02.parquet
::Enter the full path to file
set LOCAL_JOB_CONFIG_PATH=yourpath\Databricks_Job_Config.json


:: Login with azcopy
call azcopy login	

:: Upload local files to Azure Storage account
call azcopy copy "%LOCAL_PATH_TO_FILE%" "https://%DESTINATION_STORAGE_ACCOUNT_NAME%.blob.core.windows.net/%DESTINATION_STORAGE_CONTAINER_NAME%/%DESTINATION_FILE_NAME%"


::Create Databricks Job
call databricks jobs create --json-file %LOCAL_JOB_CONFIG_PATH%





