<#
.DESCRIPTION
# This script is designed to upgrade all installed packages using the Windows Package Manager (winget).
# It checks if the script is running as Administrator, creates a temporary directory if it doesn't exist, and then upgrades all installed packages.
# It also installs specific packages (7zip, Putty, winscp, tightVNC and x2go and Xming using winget.

.NOTES
Version: 1.0.1
Date: 2025
Author: Chris Hawkins and AI Assistant

.EXAMPLE
$cmdLogManager = New-Object CommandLogManager
$cmdLogManager.LogCommand("Get-Process")

.LINK
https://github.com/catchcoder/powershell-scripts
#>
# Check if the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an Administrator." -ErrorAction Stop
}

# Set execution policy
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force

# hashtable for packages and their custom parameters
# The keys are the package IDs and the values are the custom parameters for installation:
$packagesAndCustomParams = @{
    '7zip.7zip'         = '-e'
    'PuTTY.PuTTY'       = '-e'
    'WinSCP.WinSCP'     = '-e'
    'GlavSoft.TightVNC' = '-e --custom ADDLOCAL=Viewer'  # VNC Viewer ONLY, do not install VNCserver
    'Xming.Xming'       = '-e'
    'X2go.x2goclient'   = '-e'
}

# Create a temporary directory if it doesn't exist
$tempDir = Join-Path $env:TEMP "WingetUpgradeLogs"
if (-not (Test-Path -Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Create log file path in temp folder with timestamp
$logFile = Join-Path $tempDir ("package_updates_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# Start logging
"Package Update Log - $(Get-Date)" | Out-File -FilePath $logFile

# Get the full path of winget
# $wingetPath = (Get-Command winget).Source
$wingetPath = Join-Path (Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation "winget.exe"

# Define the default switches for winget install
# These switches are common for all installations
$defaultSwitches = "--accept-source-agreements --accept-package-agreements --verbose"

# Install packages
foreach ($package in $packagesAndCustomParams.Keys) {
    try {
        $params = $packagesAndCustomParams[$package]
        $fullcommand = "$wingetPath upgrade --id $package $params $defaultSwitches"
        "Checking package: $package" | Tee-Object -FilePath $logFile -Append
        $upgradeResult = Invoke-Expression $fullcommand 
        if ($LASTEXITCODE -eq 0) {
            "Successfully updated $package" | Tee-Object -FilePath $logFile -Append
        } else {
            "No updates available for $package" | Tee-Object -FilePath $logFile -Append
        }
    }
    catch {
        "Error updating $package : $_" | Tee-Object -FilePath $logFile -Append
    }
    "" | Tee-Object -FilePath $logFile -Append
}

"Update process completed. Log file: $logFile" | Write-Host
# End logging
"Update process completed - $(Get-Date)" | Tee-Object -FilePath $logFile -Append