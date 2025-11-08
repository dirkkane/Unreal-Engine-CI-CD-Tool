:: Config
set "RELEASE_TAG=%baseName%%version%_%hash%"
set "RELEASE_NAME=%baseName%%version%_%hash%"
set "RELEASE_DESC=Automated release via CI/CD"
set "PACKAGE_TYPE=generic"

:: Get Latest Package
echo Fetching latest package ID for project %GIT_PROJECT_ID%...

curl --silent --header "PRIVATE-TOKEN: %TOKEN%" ^
    "%GITLAB_PRIVATE_IP%/api/v4/projects/%GIT_PROJECT_ID%/packages?package_type=%PACKAGE_TYPE%&order_by=created_at&sort=desc&per_page=1" ^
    > tmp_packages.json

for /f "delims=" %%i in ('jq -r ".[0].id" tmp_packages.json') do set "PACKAGE_ID=%%i"

if "%PACKAGE_ID%"=="" (
    echo [ERROR] Could not retrieve package ID.
    type tmp_packages.json
    exit /b 1
)

echo Found latest package ID: %PACKAGE_ID%

:: Get Package File Info
curl --silent --header "PRIVATE-TOKEN: %TOKEN%" ^
    "%GITLAB_PRIVATE_IP%/api/v4/projects/%GIT_PROJECT_ID%/packages/%PACKAGE_ID%/package_files?order_by=created_at&sort=desc&per_page=1" ^
    > tmp_files.json

for /f "delims=" %%i in ('jq -r ".[0].file_name" tmp_files.json') do set "PACKAGE_FILENAME=%%i"
for /f "delims=" %%i in ('jq -r ".[0].id" tmp_files.json') do set "PACKAGE_FILE_ID=%%i"

set "PACKAGE_URL=%GITLAB_PUBLIC_IP%/%GIT_GROUP_NAME%/%GIT_PROJECT_NAME%/-/package_files/%PACKAGE_FILE_ID%/download"

echo Package file: %PACKAGE_FILENAME%
echo Package file ID: %PACKAGE_FILE_ID%
echo Package file URL: %PACKAGE_URL%

:: Create Release and Link Package
echo Creating release "%RELEASE_TAG%"...

:: Create JSON payload
(
echo {
echo   "name": "%RELEASE_NAME%",
echo   "tag_name": "%RELEASE_TAG%",
echo   "ref": "main",
echo   "description": "%RELEASE_DESC%",
echo   "assets": {
echo     "links": [
echo       {
echo         "name": "%RELEASE_NAME%",
echo         "url": "%PACKAGE_URL%",
echo         "link_type": "other"
echo       }
echo     ]
echo   }
echo }
) > tmp_release_payload.json

curl --silent ^
    --header "PRIVATE-TOKEN: %TOKEN%" ^
    --header "Content-Type: application/json" ^
    --data "@tmp_release_payload.json" ^
    --request POST "%GITLAB_PRIVATE_IP%/api/v4/projects/%GIT_PROJECT_ID%/releases" ^
    > tmp_release.json

echo Created release response:
type tmp_release.json

:: Delete temp files
echo.
del tmp_files.json
del tmp_packages.json
del tmp_release.json
del tmp_release_payload.json
exit /b 0