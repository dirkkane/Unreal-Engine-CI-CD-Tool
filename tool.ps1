# ================================
#   GLOBAL INITIALIZATION
# ================================

$ScriptRoot = Split-Path -Parent $PSCommandPath

# ================================
# Create logs folder
# ================================
$LogDir = Join-Path $ScriptRoot "logs"
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")

$LogFile = Join-Path $LogDir ("tool_log_{0}.txt" -f $timestamp)

Start-Transcript -Path $LogFile -Append | Out-Null

# ================================
#   LOAD .ENV FILE
# ================================
$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            $key = $matches[1]
            $val = $matches[2]
            Set-Item -Path "Env:$key" -Value $val
        }
    }
}

# ================================
#   CORE FUNCTIONS
# ================================
function Run-CICD { 
	Write-Host "Running CI/CD..."

	$newCommits = Pull-LatestCommits

	if ($newCommits) {
		Build-Project "Shipping"
		Publish-Build
	}
	else {
		Write-Host "Stopping..." -ForegroundColor Yellow
	}
}
function Build-Project { 
    param (
        [string]$BuildType
    )
	# ---------------------------------------------
	# Load variables
	# ---------------------------------------------
	$RepoDir       = $env:REPO_DIRECTORY
	$BuildDir      = $env:BUILD_DIRECTORY
	$ProjectName   = $env:PROJECT_NAME
	$UnrealInstall = $env:UE_INSTALLATION
	$UAT           = "$UnrealInstall\Engine\Build\BatchFiles\RunUAT.bat"
	$uproject      = "$RepoDir\$ProjectName.uproject"
	$UnrealExe     = "$UnrealInstall\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
	$timestamp     = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
	
	# ---------------------------------------------
	# Check required files
	# ---------------------------------------------
	if (-not $UAT) {
		throw "Could not find UAT at $UAT"
	}
	if (-not $uproject) {
		throw "Could not find .uproject at $uproject"
	}
	if (-not $UnrealExe) {
		throw "Could not find Unreal Executable at $UnrealExe"
	}

	# ---------------------------------------------
	# Get short Git hash
	# ---------------------------------------------
	Push-Location $RepoDir
	$hash = (git rev-parse --short HEAD 2>$null).Trim()
	if (-not $hash) {
		Write-Warning "Could not retrieve commit hash from Git." -ForegroundColor Yellow
	}
	Pop-Location
	
	# ---------------------------------------------
	# Generate build name
	# ---------------------------------------------
	$BuildName = $ProjectName + "_" + $BuildType + "_" + $timestamp + "_" + $hash
	Write-Host "Build Name: $BuildName" -ForegroundColor Yellow
	
	# ---------------------------------------------
	# Run Unreal Build (UAT)
	# ---------------------------------------------
	Push-Location $BuildDir
	
	Write-Host "Starting Unreal Build Tool..." -ForegroundColor Yellow
	Write-Host "Using project: $uproject" -ForegroundColor Yellow
	Write-Host ""
	
	if ($BuildType -eq "Shipping") {
		cmd.exe /c "`"$UAT`" -ScriptsForProject=`"$uproject`" Turnkey -command=VerifySdk -platform=Win64 -UpdateIfNeeded -EditorIO -EditorIOPort=53614 -project=`"$uproject`" BuildCookRun -nop4 -utf8output -nocompileeditor -skipbuildeditor -cook -project=`"$uproject`" -target=$ProjectName -unrealexe=`"$UnrealExe`" -platform=Win64 -installed -stage -archive -package -build -pak -iostore -compressed -prereqs -archivedirectory=`"$BuildDir`" -distribution -clientconfig=$BuildType -nodebuginfo -nocompile -nocompileuat -CrashReporter"
	} else {
		cmd.exe /c "`"$UAT`" -ScriptsForProject=`"$uproject`" Turnkey -command=VerifySdk -platform=Win64 -UpdateIfNeeded -EditorIO -EditorIOPort=53614 -project=`"$uproject`" BuildCookRun -nop4 -utf8output -nocompileeditor -skipbuildeditor -cook -project=`"$uproject`" -target=$ProjectName -unrealexe=`"$UnrealExe`" -platform=Win64 -installed -stage -archive -package -build -pak -iostore -compressed -prereqs -archivedirectory=`"$BuildDir`" -distribution -clientconfig=$BuildType -nocompile -nocompileuat -CrashReporter" 
	}
	
	if ($LASTEXITCODE -ne 0) {
		throw "UAT build failed."
	}
	
	if ($BuildType -eq "Shipping"){
		# ---------------------------------------------
		# Cleanup Unwanted Files
		# ---------------------------------------------
		Write-Host "Cleaning up unwanted files..." -ForegroundColor Yellow
		
		# ---------------------------------------------
		# Remove .txt in Windows folder
		# ---------------------------------------------
		Get-ChildItem "$BuildDir\Windows" -Filter *.txt -Recurse -Force -ErrorAction SilentlyContinue |
			Remove-Item -Force -ErrorAction SilentlyContinue
			
		# ---------------------------------------------
		# Remove Extras folder
		# ---------------------------------------------
		$extras = "$BuildDir\Windows\Engine\Extras"
		if (Test-Path $extras) {
			Remove-Item $extras -Recurse -Force -ErrorAction SilentlyContinue
		}
		
		# ---------------------------------------------
		# Remove PDB files
		# ---------------------------------------------
		Get-ChildItem "$BuildDir\Windows" -Filter *.pdb -Recurse -Force -ErrorAction SilentlyContinue |
			Remove-Item -Force -ErrorAction SilentlyContinue
	}
	
		
	# ---------------------------------------------
	# Archive build
	# ---------------------------------------------
	Write-Host "Archiving build as: $BuildName.7z" -ForegroundColor Yellow
	
	cmd.exe /c "C:\Program Files\7-Zip\7z.exe" a -t7z -m0=lzma2 -mx=9 "$BuildName.7z" ".\Windows"

	Write-Host "Archive created as $BuildName.7z" -ForegroundColor Yellow

	# ---------------------------------------------
	# Remove Uncompressed Build
	# ---------------------------------------------
	Remove-Item -Recurse -Force "$BuildDir\Windows"
	
	Write-Host "`nBuild completed successfully.`n" -ForegroundColor Green
	
	Pop-Location
	}
function Publish-Build { 
	Write-Host "Publishing build..." 
	# ---------------------------------------------
	# Load variables
	# ---------------------------------------------
	$TokenUsername   = $env:TOKEN_USERNAME
	$Token           = $env:TOKEN
	$BuildDir        = $env:BUILD_DIRECTORY
	$GitlabPublicIP  = $env:GITLAB_PUBLIC_IP
	$GitlabPrivateIP = $env:GITLAB_PRIVATE_IP
	$GitProjectID    = $env:GIT_PROJECT_ID
	$GitNamespace    = $env:GIT_NAMESPACE
	$GitProjectName  = $env:GIT_PROJECT_NAME
	$ReleaseDesc     = "Automated release via CI/CD"
	$PackageType     = "generic"

	# ---------------------------------------------
	# Get latest build
	# ---------------------------------------------
	$LatestBuild = (Get-ChildItem -Path $BuildDir -Filter "*.7z" |
    	Sort-Object LastWriteTime -Descending |
    	Select-Object -First 1
	).BaseName

	Write-Host "Using build: $LatestBuild" -ForegroundColor Yellow

	$ReleaseTag = "$LatestBuild"
	$ReleaseName = "$LatestBuild"

	# ---------------------------------------------
	# Upload file 
	# TODO: REPLACE WITH INVOKE-RESTMETHOD
	# ---------------------------------------------
	$uploadresponse = cmd.exe /c curl --location --user "$TokenUsername^:$Token" --upload-file "$BuildDir\$LatestBuild.7z" "$GitlabPrivateIP/api/v4/projects/$GitProjectID/packages/$PackageType/$LatestBuild/$LatestBuild/$LatestBuild.7z"

	# ---------------------------------------------
	# Check exit code from curl
	# ---------------------------------------------
	if ($LASTEXITCODE -ne 0) {
	    throw "Build upload failed (curl returned a non-zero exit code)."
	}

	# ---------------------------------------------
	# Parse JSON safely
	# ---------------------------------------------
	try {
	    $json = $uploadresponse | ConvertFrom-Json
	} 
	catch {
	    throw "Upload response was not valid JSON: $uploadresponse"
	}

	# ---------------------------------------------
	# Validate response message
	# ---------------------------------------------
	if ($json.message -eq "201 Created") {
	    Write-Host "Build uploaded successfully." -ForegroundColor Green
	}
	else {
	    throw "Upload failed, server returned message: $($json.message)"
	}

	# ==============================
	# Get Latest Package
	# ==============================
	Write-Host "Fetching latest package ID for project $GitProjectID ..."

	$packagesJson = Invoke-RestMethod -Method Get `
	    -Headers @{ "PRIVATE-TOKEN" = $TOKEN } `
	    -Uri "$GitlabPrivateIP/api/v4/projects/$GitProjectID/packages?package_type=$PackageType&order_by=created_at&sort=desc&per_page=1" `

	# ==============================
	# Extract package ID from JSON
	# ==============================
	$PackageID = $packagesJson[0].id

	if ([string]::IsNullOrWhiteSpace($PackageID)) {
		throw "Could not retrieve package ID."
	    exit 1
	}

	Write-Host "Found latest package ID: $PackageID"

	# ==============================
	# Get Package File Info
	# ==============================
	$filesJson = Invoke-RestMethod -Method Get `
	    -Headers @{ "PRIVATE-TOKEN" = $TOKEN } `
	    -Uri "$GitlabPrivateIP/api/v4/projects/$GitProjectID/packages/$PackageID/package_files?order_by=created_at&sort=desc&per_page=1" `

	$PackageFilename = $filesJson[0].file_name
	$PackageFileID  = $filesJson[0].id

	$PackageURL = "$GitlabPublicIP/$GitNamespace/$GitProjectName/-/package_files/$PackageFileID/download"

	Write-Host "Package file name: $PackageFilename" -ForegroundColor Yellow
	Write-Host "Package file ID:   $PackageFileID" -ForegroundColor Yellow
	Write-Host "Package file URL:  $PackageURL" -ForegroundColor Yellow

	# ==============================
	# Create Release JSON Payload
	# ==============================

	$releasePayload = @{
	    name        = $ReleaseName
	    tag_name    = $ReleaseTag
	    ref         = "main"
	    description = $ReleaseDesc
	    assets      = @{
	        links = @(
	            @{
	                name      = $ReleaseName
	                url       = $PackageURL
	                link_type = "other"
	            }
	        )
	    }
	}

	Write-Host "Creating release '$ReleaseTag'..." -ForegroundColor Yellow

	$releaseJson = Invoke-RestMethod -Method Post `
	    -Headers @{
	        "PRIVATE-TOKEN" = $TOKEN
	        "Content-Type"  = "application/json"
	    } `
	    -Uri "$GitlabPrivateIP/api/v4/projects/$GitProjectID/releases" `
	    -Body ($releasePayload | ConvertTo-Json -Depth 10)

	Write-Host "Created release response:"
	$releaseJson | ConvertTo-Json -Depth 10
	Write-Host "Done."
}
function Pull-LatestCommits {
	Push-Location $env:REPO_DIRECTORY
    Write-Host "Pulling latest commits..."
	# ==============================
	# Get current branch name
	# ==============================
	$branch = git rev-parse --abbrev-ref HEAD 2>$null
	$branch = $branch.Trim()

	if (-not $branch) {
	    Write-Host "Could not determine current branch." -ForegroundColor Red
		Pop-Location
	}
	
	# ==============================
	# Count how many commits local is behind remote
	# ==============================
	try {
		git fetch origin | Out-Null
		$behind = git rev-list "HEAD..origin/$branch" --count

		if ($behind -gt 0) {
		    Write-Host "New commits are available on origin/$branch." -ForegroundColor Yellow
			git pull origin $branch
			return $true | Out-Null
		} else {
		    Write-Host "No new commits available." -ForegroundColor Yellow
			return $false | Out-Null
		}
	}
	finally {
		Pop-Location
	}

}
function Revert-PreviousCommit {
    Write-Host "Reverting to previous commit..."
    Push-Location $env:REPO_DIRECTORY
	git reset --hard HEAD~1
	Pop-Location
}
function Quit-Tool {
    Write-Host "Exiting tool..."
    Stop-Transcript | Out-Null
    exit
}


# ================================
#   MENU
# ================================
function Show-Menu {
    Clear-Host
    Write-Host "**********************************************************************************"
    Write-Host "*  _    _ ______    _____ _____     _______ _____    _______ ____   ____  _      *"
    Write-Host "* | |  | |  ____|  / ____|_   _|   / / ____|  __ \  |__   __/ __ \ / __ \| |     *"
    Write-Host "* | |  | | |__    | |      | |    / / |    | |  | |    | | | |  | | |  | | |     *"
    Write-Host "* | |  | |  __|   | |      | |   / /| |    | |  | |    | | | |  | | |  | | |     *"
    Write-Host "* | |__| | |____  | |____ _| |_ / / | |____| |__| |    | | | |__| | |__| | |____ *"
    Write-Host "*  \____/|______|  \_____|_____/_/   \_____|_____/     |_|  \____/ \____/|______|*"
	Write-Host "*                                                                                *"
    Write-Host "**********************************************************************************"
    Write-Host "Unreal Engine CI/CD Tool for GitLab"
    Write-Host ""
    Write-Host "Available options:"
    Write-Host "	1 - Run CI/CD (If New Commits Are Available: Pull, Build, & Publish)"
    Write-Host "	2 - Build Project (Shipping)"
    Write-Host "	3 - Build Project (Debug)"
    Write-Host "	4 - Publish Latest Build"
    Write-Host "	5 - Pull Latest Commits"
    Write-Host "	6 - Revert To Previous Commit"
    Write-Host "	7 - Quit"
    Write-Host ""
}

function Handle-MenuSelection {
    param([string]$choice)

    switch ($choice) {
        "1" { Run-CICD }
        "2" { Build-Project "Shipping"}
        "3" { Build-Project "DebugGame"}
        "4" { Publish-Build }
        "5" { Pull-LatestCommits }
        "6" { Revert-PreviousCommit }
        "7" { Quit-Tool }
        default { Write-Host "Invalid selection." }
    }
    Write-Host ""
    Write-Host "     .--."
    Write-Host "    (O)(O)"
    Write-Host "    | o /"
    Write-Host "    |``-/"
    Write-Host "    |_/"
    Write-Host "    _"
    Write-Host "   (_)   All tasks completed."
    Write-Host ""
    Write-Host "`nIt is safe to close this window or press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ================================
#   ARGUMENT MODE
# ================================
if ($args.Count -gt 0) {
    Write-Host "Arguments passed: $args"

    foreach ($arg in $args) {
        switch ($arg.ToLower()) {
            "cicd"        { Run-CICD }
            "build"       { Build-Project "Shipping"}
            "build-debug" { Build-Project "DebugGame"}
            "publish"     { Publish-Build }
            "pull"        { Pull-LatestCommits }
            "revert"      { Revert-PreviousCommit }
			"help"        { Write-Host "Unreal Engine CI/CD Tool" 
							Write-Host "Usage:" 
							Write-Host "" 
							Write-Host "	cicd - Fetch latest changes from Git, build the project, archive into a .7z, and publish to GitLab." 
							Write-Host "	build - Creates a Shipping build of the Unreal project."
							Write-Host "	build-debug - Creates a DebugGame build of the Unreal project."
							Write-Host "	publish - Unpload the latest build to GitLab and publish as a release."
							Write-Host "	pull - Fetches and pulls the latest changes from Git."
							Write-Host "	revert - Reverts local project repo to the previous commit."
							Write-Host "	help - Prints this help message."}
            default       { Write-Host "Unknown argument: $arg" 
							Write-Host "Usage:" 
							Write-Host "" 
							Write-Host "	cicd - Fetch latest changes from Git, build the project, archive into a .7z, and publish to GitLab." 
							Write-Host "	build - Creates a Shipping build of the Unreal project."
							Write-Host "	build-debug - Creates a DebugGame build of the Unreal project."
							Write-Host "	publish - Unpload the latest build to GitLab and publish as a release."
							Write-Host "	pull - Fetches and pulls the latest changes from Git."
							Write-Host "	revert - Reverts local project repo to the previous commit."
							Write-Host "	help - Prints this help message."}
        }
    }

    Write-Host ""
    Write-Host "     .--."
    Write-Host "    (O)(O)"
    Write-Host "    | o /"
    Write-Host "    |``-/"
    Write-Host "    |_/"
    Write-Host "    _"
    Write-Host "   (_)   All tasks completed."
    Write-Host ""
    Stop-Transcript | Out-Null
    exit
}


# ================================
#   MAIN MENU LOOP
# ================================
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter the number of your choice, then press enter"
    Handle-MenuSelection $choice
}
