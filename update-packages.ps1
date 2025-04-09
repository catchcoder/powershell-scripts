<#
.DESCRIPTION
# This script is designed to upgrade all installed packages using the Windows Package Manager (winget).
# It checks if the script is running as Administrator, creates a temporary directory if it doesn't exist, and then upgrades all installed packages.
# It also installs specific packages (7zip, Putty, winscp, tightVNC and x2go and Xming using winget.

.NOTES
Version: 1.0.0
Date: 2025
Author: Chris Hawkins and AI Assistant

.EXAMPLE
$cmdLogManager = New-Object CommandLogManager
$cmdLogManager.LogCommand("Get-Process")

.LINK
https://github.com/yourusername/CommandLogManager
#>
# Check if the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an Administrator." -ErrorAction Stop
}

# Set execution policy
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force



# Array of packages to install
$packages = @(
    "7zip.7zip",
    "PuTTY.PuTTY",
    "WinSCP.WinSCP",
    "GlavSoft.TightVNC",
    "X2go.x2goclient",
    "Xming.Xming"
    )

# Create a temporary directory if it doesn't exist
$tempDir = Join-Path $env:TEMP "WingetUpgradeLogs"
if (-not (Test-Path -Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Create log file path in temp folder with timestamp
$logFile = Join-Path $env:TEMP ("package_updates_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# Start logging
"Package Update Log - $(Get-Date)" | Out-File -FilePath $logFile

# Get the full path of winget
# $wingetPath = (Get-Command winget).Source
$wingetPath = Join-Path (Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation "winget.exe"

foreach ($package in $packages) {
    try {
        "Checking package: $package" | Tee-Object -FilePath $logFile -Append
        $upgradeResult = & $wingetPath upgrade $package --accept-source-agreements
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