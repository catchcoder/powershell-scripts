<#
.SYNOPSIS
    Installs NodeJS and 7zip utility using winget for OxCal (https://c14.arch.ox.ac.uk/oxcal.html) installation.
.DESCRIPTION
    This script installs various packages including 7zip and NodeJS. Requires administrative privileges and PowerShell 5+.
.NOTES
    Version: 1.01
    Author: Chris Hawkins and AI Assistant
    Date: 2025
#>
# Set up logging
$logFile = Join-Path $env:TEMP "oxcal-packages-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
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
#$region = "GB"
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "GeoID" -Value ([System.Globalization.RegionInfo]::CurrentRegion.GeoId)

# hashtable for packages and their custom parameters
# The keys are the package IDs and the values are the custom parameters for installation:
$packagesAndCustomParams = @{
    '7zip.7zip'         = '-e'
    'OpenJS.NodeJS'       = '-e'

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

$OXCAL_URI_DOWNLOAD = "https://c14.arch.ox.ac.uk/OxCalDistribution.zip"
$OXCAL_INSTALL_DIR = "C:\Program Files"

# Create OxCal directory if it doesn't exist
if (-not (Test-Path -Path $OXCAL_INSTALL_DIR)) {
    New-Item -Path $OXCAL_INSTALL_DIR -ItemType Directory -Force
}

# Download OxCal distribution
Write-Host "Downloading OxCal..."
try {
    Invoke-WebRequest -Uri $OXCAL_URI_DOWNLOAD -OutFile "$env:TEMP\OxCalDistribution.zip"
}
catch {
    Write-Error "Failed to download OxCal: $_" -ErrorAction Stop
}

# Extract using 7-Zip
Write-Host "Extracting OxCal..."
try {
    & 'C:\Program Files\7-Zip\7z.exe' x "$env:TEMP\OxCalDistribution.zip" "-o$OXCAL_INSTALL_DIR" -y
}
catch {
    Write-Error "Failed to extract OxCal: $_" -ErrorAction Stop
}

# Clean up
Remove-Item "$env:TEMP\OxCalDistribution.zip" -Force

# Create OxCal folder in user's home directory, this is where all data will be stored
# This is the location where the OxCal application will look for its data files
$oxcalUserDir = Join-Path $env:USERPROFILE "OxCal"
if (-not (Test-Path -Path $oxcalUserDir)) {
    New-Item -Path $oxcalUserDir -ItemType Directory -Force
    Write-Host "Created OxCal directory at $oxcalUserDir"
}

# Create desktop shortcut for OxCal
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\OxCal.lnk")
$Shortcut.TargetPath = "C:\Program Files\OxCal\OxCal.bat"
$Shortcut.WorkingDirectory = "C:\Program Files\OxCal"
$Shortcut.Description = "OxCal Application"
$Shortcut.Save()
Write-Host "Desktop shortcut created for OxCal"

# Launch Edge browser with OxCal local server
Start-Process "msedge" -ArgumentList "http://localhost:8080"


Write-Host "Installation complete!"

# Stop logging
Stop-Transcript
# End of script 