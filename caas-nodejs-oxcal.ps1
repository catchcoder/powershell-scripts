<#
.SYNOPSIS
    Installs NodeJS and 7zip utility using winget for OxCal (https://c14.arch.ox.ac.uk/oxcal.html) installation.
.DESCRIPTION
    This script installs various packages including 7zip and NodeJS. Requires administrative privileges and PowerShell 5+.
.NOTES
    Version: 1.03
    Author: Chris Hawkins and Copilot AI Assistant
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

# System check complete notification
Write-Host "`n=== System Check Complete ===" -ForegroundColor Green
Write-Host "All prerequisites verified. Starting OxCal installation..." -ForegroundColor Green
Write-Host "=============================`n" -ForegroundColor Green

# hashtable for packages and their custom parameters
# The keys are the package IDs and the values are the custom parameters for installation:
$packagesAndCustomParams = @{
    '7zip.7zip'         = '-e'
    'OpenJS.NodeJS'      = '-e'
    'RProject.R'         = '-e'
    'RStudio.RStudio'    = '-e'
    'RProject.R'                 = '-e --scope machine'
    'RStudio.RStudio'            = '-e --scope machine'
    'Microsoft.VisualStudioCode' = '-e --scope machine' 
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

# variables for OxCal installation
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

# Verify OxCal installation
$nodeServerPath = "C:\Program Files\OxCal\NodeServer.js"
if (-not (Test-Path -Path $nodeServerPath)) {
    Write-Error "OxCal installation failed: NodeServer.js not found at $nodeServerPath" -ErrorAction Stop
}
Write-Host "OxCal installation verified: NodeServer.js found at $nodeServerPath"


# Create OxCal folder in user's home directory, this is where all data will be stored
# This is the location where the OxCal application will look for its data files
$oxcalUserDir = Join-Path $env:USERPROFILE "OxCal"
if (-not (Test-Path -Path $oxcalUserDir)) {
    New-Item -Path $oxcalUserDir -ItemType Directory -Force
    Write-Host "Created OxCal directory at $oxcalUserDir"
}

# Create OxCal folder on C: drive
$oxcalPath = "C:\oxcal"
if (-not (Test-Path -Path $oxcalPath)) {
    New-Item -Path $oxcalPath -ItemType Directory -Force
}

# Set permissions for all users to read and write
$acl = Get-Acl $oxcalPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users","Modify","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $oxcalPath $acl

Write-Host "Created OxCal directory at $oxcalPath with read/write permissions for all users"

# Create desktop shortcut for OxCal
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\OxCal.lnk")
$Shortcut.TargetPath = "C:\Program Files\OxCal\OxCal.bat"
$Shortcut.WorkingDirectory = "C:\Program Files\OxCal"
$Shortcut.Description = "OxCal Application"
$Shortcut.Save()
Write-Host "Desktop shortcut created for OxCal in Public desktop"

# Create desktop shortcut for OxCal Web Interface in Public desktop
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\OxCal Web.lnk")
$Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$Shortcut.Arguments = "http://localhost:8080"
$Shortcut.Description = "OxCal Web Interface"
$Shortcut.Save()
Write-host "Desktop shortcut created for OxCal Web Interface in Public desktop"

# Launch Edge browser with OxCal local server
Start-Process "msedge" -ArgumentList "http://localhost:8080"


Write-Host "Installation complete!"

# Remove Internet Explorer from Windows Server 2019
Write-Host "Removing Internet Explorer..."
try {
    Disable-WindowsOptionalFeature -Online -FeatureName "Internet-Explorer-Optional-amd64" -NoRestart
    Write-Host "Internet Explorer has been removed successfully"
} catch {
    Write-Warning "Failed to remove Internet Explorer: $_"
}

# Note: The removal of Internet Explorer may require a system restart to take effect.
# Notify user about the need for a restart
Write-Warning "`nA system restart is required to completely remove Internet Explorer. Please restart your system manually."

# Notify user about the installation completion
Write-Host "`n=== Installation is Complete ===" -ForegroundColor Green
Write-Host "       OxCal installed" -ForegroundColor Green
Write-Host "================================`n" -ForegroundColor Green

# Stop logging
Stop-Transcript
# End of script 