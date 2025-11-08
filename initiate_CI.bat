:: Change directory to your repo
cd %REPO_DIRECTORY%

:: Fetch latest changes from origin
git fetch >nul 2>&1

:: Get the name of the current branch
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set BRANCH=%%b

:: Compare local and remote
for /f "delims=" %%s in ('git rev-list HEAD..origin/%BRANCH% --count') do set BEHIND=%%s

if %BEHIND% gtr 0 (
    echo New commits are available on origin/%BRANCH%.
    call :on_update
) else (
    echo No new commits available.
    echo No new commits, build not necessary...
	goto :eof
)

goto :eof

:: Function for when updates are found
:on_update
echo Pulling changes and building...

git pull
call %CI_directory%/build_game.bat

:: Upload to Drop Zone

echo Uploading archive to Drop Zone...
curl --location --user "%TOKEN_USERNAME%:%TOKEN%" --upload-file "%BUILD_DIRECTORY%\%baseName%%version%_%hash%.7z" "%GITLAB_PRIVATE_IP%/api/v4/projects/%GIT_PROJECT_ID%/packages/generic/%year%.%month%.%day%_%hash%/%baseName%%version%_%hash%/%baseName%%version%_%hash%.7z"

echo Creating release...
call %CI_directory%/create_release.bat

goto :eof
