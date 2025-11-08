@echo off
setlocal enabledelayedexpansion enableextensions
cls

set CI_directory="%~dp0"
cd /d "%~dp0"

:: Read .env
set "configFile=.env"
for /f "delims=" %%i in (%configFile%) do (
    call %%i
)

:: Get current date
for /f "tokens=2 delims==" %%I in ('"wmic os get localdatetime /value"') do set datetime=%%I
set year=%datetime:~0,4%
set month=%datetime:~4,2%
set day=%datetime:~6,2%

set RUN_CI=false
set RUN_BUILD=false
set RUN_PULL_CHANGES=false
set RUN_REVERT_COMMIT=false
set RUN_QUIT=false

:main
if "%~1"=="" (
	echo """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    echo "  _    _ ______    _____ _____     _______ _____    _______ ____   ____  _      "
    echo " | |  | |  ____|  / ____|_   _|   / / ____|  __ \  |__   __/ __ \ / __ \| |     "
    echo " | |  | | |__    | |      | |    / / |    | |  | |    | | | |  | | |  | | |     "
    echo " | |  | |  __|   | |      | |   / /| |    | |  | |    | | | |  | | |  | | |     "
    echo " | |__| | |____  | |____ _| |_ / / | |____| |__| |    | | | |__| | |__| | |____ "
    echo "  \____/|______|  \_____|_____/_/   \_____|_____/     |_|  \____/ \____/|______|"
    echo "                                                                                "
	echo """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
	echo[
	echo Unreal Engine CI/CD Tool for GitLab
	echo[
    echo Available options:
    echo 	1- Run CI/CD (Fetch Changes, Build, Package, Publish^)
	echo 	2- Build Project
	echo 	3- Pull Latest Commits
    echo 	4- Revert To Previous Commit
    echo 	5- Quit
    set /p choice="Enter the number of your choice, then press enter: "
    if "!choice!"=="1" set RUN_CI=true
	if "!choice!"=="2" set RUN_BUILD=true
	if "!choice!"=="3" set RUN_PULL_CHANGES=true
    if "!choice!"=="4" set RUN_REVERT_COMMIT=true
    if "!choice!"=="5" set RUN_QUIT=true
    goto process_commands
)

:parse_args
if "%~1"=="" goto process_commands
if /i "%~1"=="RunCI" set RUN_CI=true
if /i "%~1"=="Build" set RUN_BUILD=true
if /i "%~1"=="PullChanges" set RUN_PULL_CHANGES=true
if /i "%~1"=="RevertCommit" set RUN_REVERT_COMMIT=true
if /i "%~1"=="Quit" set RUN_QUIT=true

shift
goto parse_args

:process_commands
if "!RUN_REVERT_COMMIT!"=="true" (
    echo Reverting to previous commit...
    pushd "%~dp0"
    cd %REPO_DIRECTORY%
	git reset --hard HEAD~1
    popd
)

if "!RUN_PULL_CHANGES!"=="true" (
    echo Checking for new commits...
    pushd "%~dp0"
	:: Change directory to your repo
	cd %REPO_DIRECTORY%
	:: Fetch latest changes from origin
	git fetch >nul 2>&1
	:: Get the name of the current branch
	for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set BRANCH=%%b
	
	:: Compare local and remote
	for /f "delims=" %%s in ('git rev-list HEAD..origin/!BRANCH! --count') do set BEHIND=%%s
	
	if !BEHIND! gtr 0 (	
	echo New commits are available on origin/!BRANCH!.	
	git pull
	) else (	
	echo No new commits available.
	)
	popd
)

if "!RUN_BUILD!"=="true" (
    echo Building game...
    pushd "%~dp0"
    call "build_game.bat"
    popd
)

if "!RUN_CI!"=="true" (
    echo Running CI/CD...
    pushd "%~dp0"
    call "initiate_CI.bat"
    popd
)

if "!RUN_QUIT!"=="true" (
    pushd "%~dp0"
    exit /b 0
    popd
)

	echo[
	echo      .--.  
	echo     ^(O^)^(O^)  
	echo     ^| o ^/     
	echo     ^|`-^/      
	echo     ^|_^/      
	echo     _      
	echo    ^(_^)     All tasks completed.
    echo[
    echo It's safe to close this window, or
pause

set RUN_CI=false
set RUN_BUILD=false
set RUN_PULL_CHANGES=false
set RUN_REVERT_COMMIT=false
set RUN_QUIT=false

cls
goto main

