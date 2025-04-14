<#
.SYNOPSIS
    Installs common remote access and utility packages using winget.
.DESCRIPTION
    This script installs various packages including 7zip, PuTTY, WinSCP, TightVNC, 
    Xming, and X2go client. Requires administrative privileges and PowerShell 5+.
.NOTES
    Version: 1.02
    Author: Chris Hawkins and AI Assistant
    Date: 2025
#>
# Set up logging
$logFile = Join-Path $env:TEMP "quar-packages-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
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
if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue | Where-Object Version -ge '2.8.5.201')) {
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
    '7zip.7zip' = '-e'
    'PuTTY.PuTTY' = '-e'
    'WinSCP.WinSCP' = '-e'
    'GlavSoft.TightVNC' = '-e --custom ADDLOCAL=Viewer'  # VNC Viewer ONLY, do not install VNCserver
    'Xming.Xming' = '-e'
    'X2go.x2goclient' = '-e'
}

# Define the default switches for winget install
# These switches are common for all installations
$defaultSwitches = "--accept-source-agreements --accept-package-agreements --verbose"

# Install packages
foreach ($package in $packagesAndCustomParams.Keys) {
    $params = $packagesAndCustomParams[$package]
    $fullCommand = "winget install --id $package $params $defaultSwitches"
    Write-Host "Installing $package..."
    try {

        Invoke-Expression $fullcommand 
    }
    catch {
        Write-Warning "Failed to install $package $_"
    }
}

Write-Host "Installation complete!"