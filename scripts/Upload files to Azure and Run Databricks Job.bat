@echo off
:: Set Variables
::Enter the full path to file
set LOCAL_PATH_TO_FILE=
set DESTINATION_STORAGE_ACCOUNT_NAME=
set DESTINATION_STORAGE_CONTAINER_NAME=
::Enter the full path to file
set LOCAL_JOB_CONFIG_PATH=


:: Login with azcopy
azcopy Login

:: Upload local files to Azure Storage account
azcopy copy "%LOCAL_PATH_TO_FILE%" "https://%DESTINATION_STORAGE_ACCOUNT_NAME%.blob.core.windows.net/%DESTINATION_STORAGE_CONTAINER_NAME%/patients.csv"

:: Create Databricks Job
databricks jobs create --json-file %LOCAL_JOB_CONFIG_PATH%
