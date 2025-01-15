@echo off
setlocal enabledelayedexpansion
:: Set Variables
::Enter the full path to file
set LOCAL_PATH_TO_FILE=C:\Users\aashi\projects\Databricks CLI\data\green_tripdata_2024-02.parquet
set DESTINATION_STORAGE_ACCOUNT_NAME=ashilstorage
set DESTINATION_STORAGE_CONTAINER_NAME=container-raw
set DESTINATION_FILE_NAME=green_tripdata_2024-02.parquet
::Enter the full path to file
set LOCAL_JOB_CONFIG_PATH="C:\Users\aashi\projects\Databricks CLI\config\Databricks_Job_Config.json"


::Create Databricks Job
call databricks jobs create --json-file %LOCAL_JOB_CONFIG_PATH% > output.json

:: Initialize JOB_ID variable
set "JOB_ID="

:: Read the JSON file and extract the job_id
for /f "tokens=2 delims=:, " %%A in ('findstr "job_id" output.json') do (
    set "JOB_ID=%%~A"
    set "JOB_ID=!JOB_ID:~1,-1!" :: Trim any quotes if present
)

:: Clean up temporary file
del output.json

:: Display the extracted job_id
if defined JOB_ID (
    echo Job ID: %JOB_ID%
) else (
    echo Failed to extract job ID.
)

call databricks jobs run-now --job-id %JOB_ID% --notebook-params {"container_bronze":"container-bronze","container_gold":"container-gold","container_raw":"container-raw","container_silver":"container-silver","storage":"ashilstorage"}



