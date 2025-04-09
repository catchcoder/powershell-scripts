# Using Winget to install packages from a JSON file
# It also installs specific packages (7zip, Putty, TightVNC and WinSCP) using winget and JSON file.
# This script is designed to be run on a Windows system with PowerShell.

# Check if the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an Administrator." -ErrorAction Stop
    exit
}

#check is winget installed
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not installed. Please install winget and try again." -ErrorAction Stop
    Install-Script -Name winget-install
    winget-install
}

winget import -i packages.json
