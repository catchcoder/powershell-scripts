<#
.SYNOPSIS
    Installs NodeJS and OxCal (https://c14.arch.ox.ac.uk/oxcal.html).
.DESCRIPTION
    This script automates the installation and setup of OxCal and its dependencies on Windows. 
    Using WINGET to installs NodeJS, 7zip, R, RStudio, Visual Studio Code, and Firefox ESR using winget, 
    configures directories and permissions, downloads and extracts OxCal, creates configuration files and desktop shortcuts,
    and removes Internet Explorer. 
    Requires administrative privileges and PowerShell 5 or later.
.NOTES
    Version: 1.04
    Author: Chris Hawkins and Copilot AI Assistant
    Date: 2025
#>
# Requires -Version 5.0
# Requires -RunAsAdministrator  


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

# Set permissions for Administrators to modify the OxCal installation directory
$oxcalInstallSubDir = Join-Path $OXCAL_INSTALL_DIR "oxcal"
if (Test-Path $oxcalInstallSubDir) {
    $acl = Get-Acl $oxcalInstallSubDir
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Administrators", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $acl.SetAccessRule($adminRule)
    Set-Acl $oxcalInstallSubDir $acl
    Write-Host "Set Modify permissions for Administrators on $oxcalInstallSubDir"
}

# Verify OxCal installation
$nodeServerPath = "C:\Program Files\OxCal\NodeServer.js"
if (-not (Test-Path -Path $nodeServerPath)) {
    Write-Error "OxCal installation failed: NodeServer.js not found at $nodeServerPath" -ErrorAction Stop
}
Write-Host "OxCal installation verified: NodeServer.js found at $nodeServerPath"

# Create OxCal folder on C: drive
$oxcalPath = "C:\OxCal"
if (-not (Test-Path -Path $oxcalPath)) {
    New-Item -Path $oxcalPath -ItemType Directory -Force
}

# Create a folder inside C:\oxcal named after the current user's profile folder name
$userFolderName = Split-Path $env:USERPROFILE -Leaf
$userOxcalSubDir = Join-Path $oxcalPath $userFolderName
if (-not (Test-Path -Path $userOxcalSubDir)) {
    New-Item -Path $userOxcalSubDir -ItemType Directory -Force
    Write-Host "Created user-specific OxCal directory at $userOxcalSubDir"
}

# Set permissions for all users to read and write
$acl = Get-Acl $oxcalPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users","Modify","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $oxcalPath $acl

# Create setup.json in the "$OXCAL_INSTALL_DIR\oxcal" folder
$setupJsonPath = Join-Path -Path $OXCAL_INSTALL_DIR -ChildPath "oxcal\setup.json"
$setupJsonContent = @{
    port = "8080"
    home = "C:\OxCal"
    web = "C:\Program Files\OxCal"
    oxcal = "C:\Program Files\OxCal\bin\OxCalWin.exe"
    texdir = ""
    rasterizer = ""
    ok = $true
} | ConvertTo-Json -Compress

# Ensure the directory exists
$setupJsonDir = Split-Path $setupJsonPath -Parent
if (-not (Test-Path $setupJsonDir)) {
    New-Item -Path $setupJsonDir -ItemType Directory -Force | Out-Null
}

Set-Content -Path $setupJsonPath -Value $setupJsonContent 
Write-Host "Created setup.json at $setupJsonPath"

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
$Shortcut.TargetPath = "C:\Program Files\Mozilla Firefox\firefox.exe"
$Shortcut.Arguments = "http://localhost:8080"
$Shortcut.Description = "OxCal Web Interface"
$Shortcut.Save()
Write-Host "Desktop shortcut created for OxCal Web Interface in Public desktop"

#
# Notify user about the installation completion
Write-Host "`n=== OxCal Installation Complete ===" -ForegroundColor Green
Write-Host "OxCal has been installed successfully and is ready to use." -ForegroundColor Green  
Write-Host "You can access the OxCal Web Interface at http://localhost:8080" -ForegroundColor Green

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

# Set execution policy
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted -Force

# Notify user about the installation completion
Write-Host "`n=== Installation is Complete ===" -ForegroundColor Green
Write-Host "       OxCal installed" -ForegroundColor Green
Write-Host "================================`n" -ForegroundColor Green

# Stop logging
Stop-Transcript
# End of script 
