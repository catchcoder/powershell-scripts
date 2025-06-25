<#
.DESCRIPTION
# This script is designed to upgrade all installed packages using the Windows Package Manager (winget).
# It checks if the script is running as Administrator, creates a temporary directory if it doesn't exist, and then upgrades all installed packages.
# It also installs specific packages (7zip, Putty, winscp (all Users), tightVNC (Viewer only) and x2go and Xming using winget.

.NOTES
Version: 1.0.2
Date: 2025
Author: Chris Hawkins - Specialist Academic Applications Team

.LINK
https://github.com/catchcoder/powershell-scripts
#>

# Set up logging
$logFile = Join-Path $env:TEMP "quar-packages-upgrade-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $logFile -Append
Write-Host "Log file created at: $logFile"

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "This script requires PowerShell 5 or later. Current version: $($PSVersionTable.PSVersion)" -ErrorAction Stop
}

# Check if the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an Administrator." -ErrorAction Stop
}

# Set execution policy
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force

# Check and install NuGet provider
if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue | Where-Object Version -GE '2.8.5.201')) {
    Write-Host "Installing NuGet provider..."
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    }
    catch {
        Write-Error "Failed to install NuGet provider: $_" -ErrorAction Stop
    }
}

# Check if winget is installed
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "Winget not found. Installing winget..."
    try {
        Install-Script -Name winget-install -Force
        winget-install
    }
    catch {
        Write-Error "Failed to install winget: $_" -ErrorAction Stop
    }
}

# Accept the MSSTORE terms of transaction
Start-Process "powershell" -ArgumentList "winget source update --accept-source-agreements" -NoNewWindow -Wait

# Set the geographic region (replace 'US' with your 2-letter region code)
$region = "GB"
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "GeoID" -Value ([System.Globalization.RegionInfo]::CurrentRegion.GeoId)

# hashtable for packages and their custom parameters
# The keys are the package IDs and the values are the custom parameters for installation:
$packagesAndCustomParams = @{
    '7zip.7zip'                  = '-e'
    'OpenJS.NodeJS'              = '-e'
    'RProject.R'                 = '-e'
    'Posit.RStudio'              = '-e'
    'Microsoft.VisualStudioCode' = '-e --scope machine'
    'Mozilla.Firefox.ESR.uk'     = '-e'
}

# Define the default switches for winget install
# These switches are common for all installations
$defaultSwitches = "--accept-source-agreements --accept-package-agreements --verbose"

# Install packages
foreach ($package in $packagesAndCustomParams.Keys) {
    try {
        $params = $packagesAndCustomParams[$package]
        $fullcommand = "winget upgrade --id $package $params $defaultSwitches"
        "Checking package: $package" 
        $upgradeResult = Invoke-Expression $fullcommand 
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully updated $package" 
        }
        else {
            Write-Warning "No updates available for $package" 
        }
    }
    catch {
        Write-Warning "Error updating $package : $_" 
    }

}

"Update process completed. Log file: $logFile" | Write-Host
# End logging
Stop-Transcript
# End of script