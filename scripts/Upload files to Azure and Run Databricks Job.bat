@echo off
:: Set Variables
::Enter the full path to file
set LOCAL_PATH_TO_FILE=C:\Users\aashi\projects\Databricks CLI\data files\green_tripdata_2024-02.parquet
set DESTINATION_STORAGE_ACCOUNT_NAME=
set DESTINATION_STORAGE_CONTAINER_NAME=
::Enter the full path to file
set LOCAL_JOB_CONFIG_PATH=C:\Users\aashi\projects\Databricks CLI\config\Databricks_Job_Config.json


:: Login with azcopy
azcopy Login

:: Upload local files to Azure Storage account
azcopy copy "%LOCAL_PATH_TO_FILE%" "https://%DESTINATION_STORAGE_ACCOUNT_NAME%.blob.core.windows.net/%DESTINATION_STORAGE_CONTAINER_NAME%/patients.csv"

:: Create Databricks Job

call databricks jobs create --json-file %LOCAL_JOB_CONFIG_PATH% > job_output.json

REM Look for the "job_id" field and extract its value
for /f "tokens=2 delims=:," %%A in ('findstr /c:"job_id" job_output.json') do (
    set JOB_ID=%%A
)

REM Remove quotes and trim spaces
set JOB_ID=%JOB_ID:"=%
set JOB_ID=%JOB_ID: =%

REM Display the Job ID
call echo Job ID: %JOB_ID%

REM Clean up the temporary file
del job_output.json
