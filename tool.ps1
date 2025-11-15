# ================================
#   GLOBAL INITIALIZATION
# ================================

$ScriptRoot = Split-Path -Parent $PSCommandPath

# Create logs folder
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
	Write-Output "Running CI/CD..." 
	Start-Sleep 1 
}
function Build-Project { 
	Write-Output "Building project..." 
	Start-Sleep 1 
	}
function Publish-Build { 
	Write-Output "Publishing build..." 
	Start-Sleep 1 
}
function Pull-LatestCommits {
    Write-Output "Pulling latest commits..."
    git pull
}
function Revert-PreviousCommit {
    Write-Output "Reverting to previous commit..."
    Start-Sleep 1
}
function Quit-Tool {
    Write-Output "Exiting tool..."
    Stop-Transcript | Out-Null
    exit
}


# ================================
#   MENU
# ================================
function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  _    _ ______    _____ _____     _______ _____    _______ ____   ____  _      "
    Write-Host " | |  | |  ____|  / ____|_   _|   / / ____|  __ \  |__   __/ __ \ / __ \| |     "
    Write-Host " | |  | | |__    | |      | |    / / |    | |  | |    | | | |  | | |  | | |     "
    Write-Host " | |  | |  __|   | |      | |   / /| |    | |  | |    | | | |  | | |  | | |     "
    Write-Host " | |__| | |____  | |____ _| |_ / / | |____| |__| |    | | | |__| | |__| | |____ "
    Write-Host "  \____/|______|  \_____|_____/_/   \_____|_____/     |_|  \____/ \____/|______|"
    Write-Host ""
    Write-Host "Unreal Engine CI/CD Tool for GitLab"
    Write-Host ""
    Write-Host "Available options:"
    Write-Host "1 - Run CI/CD (Pull, Build, Publish)"
    Write-Host "2 - Build Project"
    Write-Host "3 - Publish Build"
    Write-Host "4 - Pull Latest Commits"
    Write-Host "5 - Revert To Previous Commit"
    Write-Host "6 - Quit"
    Write-Host ""
}

function Handle-MenuSelection {
    param([string]$choice)

    switch ($choice) {
        "1" { Run-CICD }
        "2" { Build-Project }
        "3" { Publish-Build }
        "4" { Pull-LatestCommits }
        "5" { Revert-PreviousCommit }
        "6" { Quit-Tool }
        default { Write-Output "Invalid selection." }
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
    Write-Output "Arguments passed: $args"

    foreach ($arg in $args) {
        switch ($arg.ToLower()) {
            "cicd"        { Run-CICD }
            "build"       { Build-Project }
            "publish"     { Publish-Build }
            "pull"        { Pull-LatestCommits }
            "revert"      { Revert-PreviousCommit }
            default       { Write-Output "Unknown argument: $arg" }
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
