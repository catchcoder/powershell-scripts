# Requires elevation (Run as Administrator)
#Requires -RunAsAdministrator

<#

# Domain To Standalone 

Convert a deployed machine to a Standalone or quarantined system.

.DESCRIPTION
**Need to run PowerShell using -a account!**

Features:
- activate Windows 10 with MAK key
- Create a local standard user and admin user
- Remove the computer from the domain
- Enable the local administrator account
- Set the local administrator password
- Remove Office 365
- Modify password policy
- Configure Security Event Log to overwrite as needed
- Export BitLocker recovery key
- Backup Bitlocker code
- Set DNS suffix

Changes todo:
- Install Office 2016
- Configure the MAK key for Office
 
.INPUTS
None. You cannot pipe objects to Generic_user.

.EXAMPLE
**Usage**
How to Use
    Open PowerShell as Administrator
    Navigate to the script location
    Before running, modify these values:
    Replace XXXXX-XXXXX-XXXXX-XXXXX-XXXXX with actual Windows MAK key
    Update YourSecurePassword123! with desired secure passwords
    Run the script:

.NOTES
Version: 1.0.1
Date: 2025
Author: Chris Hawkins and AI Assistant
#>

# Set up logging
$logFile = Join-Path $env:TEMP "windows-standalone-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
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

# Configure Windows MAK key and activate
Write-Host "Configuring Windows MAK key and activating..." -ForegroundColor Yellow
# Note: Replace the MAK key with the actual key
try {
    $windowsMakKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" # Replace with actual MAK key
    
    # Install MAK key
    $result = cscript //nologo "$env:windir\system32\slmgr.vbs" /ipk $windowsMakKey
    Write-Host $result -ForegroundColor Green
    
    # Activate Windows
    $activation = cscript //nologo "$env:windir\system32\slmgr.vbs" /ato
    Write-Host $activation -ForegroundColor Green
    
    Write-Host "Windows MAK configuration and activation completed." -ForegroundColor Green
} catch {
    Write-Host "Error configuring Windows MAK: $_" -ForegroundColor Red
}

# Modify password policy
Write-Host "Modifying password policy..." -ForegroundColor Yellow
try {
    # Set maximum password age to 0 (never expire)
    net accounts /maxpwage:unlimited
    # Set minimum password age to 0 (immediate change allowed)
    net accounts /minpwage:0
    # Set minimum password length to 0 (no minimum)
    net accounts /minpwlen:0
    # Set password history to 0 (no history)
    net accounts /uniquepw:0
    
    # Set password complexity to disabled
    # Disable password complexity requirements through Security Policy
    secedit /export /cfg C:\secpol.cfg
    (Get-Content C:\secpol.cfg).Replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
    secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
    Remove-Item -Path C:\secpol.cfg -Force

    Write-Host "Password policy modified successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error modifying password policy: $_" -ForegroundColor Red
}

# Create local standard and admin user accounts
Write-Host "Creating local standard and admin user accounts..." -ForegroundColor Yellow
try {
    # Get hostname and create usernames
    $hostname = $env:COMPUTERNAME
    $standardUser = "$hostname-user"
    $adminUser = "$hostname-admin"
    $usersPassword = "Password1234!" # Change this to your desired password
    $secureUserPassword = ConvertTo-SecureString $usersPassword -AsPlainText -Force
    
    # Create standard user account
    Write-Host "Creating standard user account: $standardUser" -ForegroundColor Yellow
    New-LocalUser -Name $standardUser -Password $secureUserPassword -FullName $standardUser -Description "Standard User Account" -PasswordNeverExpires
    Add-LocalGroupMember -Group "Users" -Member $standardUser
    
    # Create admin user account
    Write-Host "Creating admin user account: $adminUser" -ForegroundColor Yellow
    New-LocalUser -Name $adminUser -Password $secureUserPassword -FullName $adminUser -Description "Admin User Account" -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $adminUser
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

# Remove computer from domain and enable local admin account
Write-Host "Removing computer from domain and enabling local admin account..." -ForegroundColor Yellow
# Note: This requires the local admin password to be set in advance
try {
    # Define the local admin password
    $adminPassword = "YourSecurePassword123!" # Change this to your desired password

    # Create credential object for local admin
    $adminUser = "Administrator"
    $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($adminUser, $securePassword)

    # Remove computer from domain
    Write-Host "Removing computer from domain..." -ForegroundColor Yellow
    Remove-Computer -UnjoinDomainCredential $credential -Force -PassThru

    # Enable local administrator account
    Write-Host "Enabling local administrator account..." -ForegroundColor Yellow
    Enable-LocalUser -Name "Administrator"

    # Set password for local administrator
    Write-Host "Setting local administrator password..." -ForegroundColor Yellow
    Set-LocalUser -Name "Administrator" -Password $securePassword

    Write-Host "Operations completed successfully. System needs to be restarted." -ForegroundColor Green
    
    # Prompt for restart
    $restart = Read-Host "Do you want to restart the computer now? (Y/N)"
    if ($restart -eq "Y") {
        Restart-Computer -Force
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

# Remove Office 365
Write-Host "Removing Office 365..." -ForegroundColor Yellow
try {
    $office365Path = "${env:ProgramFiles}\Microsoft Office 15\ClientX64\OfficeClickToRun.exe"
    if (Test-Path $office365Path) {
        Start-Process $office365Path -ArgumentList "/uninstall platformall /forceshutdown" -Wait -NoNewWindow
        Write-Host "Office 365 removal completed successfully." -ForegroundColor Green
    } else {
        Write-Host "Office 365 installation not found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error removing Office 365: $_" -ForegroundColor Red
}

# Configure Security Event Log to overwrite as needed
Write-Host "Configuring Security Event Log..." -ForegroundColor Yellow
try {
    wevtutil set-log Security /retention:false
    Write-Host "Security Event Log configured to overwrite as needed." -ForegroundColor Green
} catch {
    Write-Host "Error configuring Security Event Log: $_" -ForegroundColor Red
}

# Export BitLocker recovery key
Write-Host "Exporting BitLocker recovery key..." -ForegroundColor Yellow
try {
    $volumes = Get-BitLockerVolume
    foreach ($volume in $volumes) {
        if ($volume.VolumeStatus -eq "FullyEncrypted") {
            $recoveryKey = $volume | Select-Object -ExpandProperty KeyProtector | 
                Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
            
            if ($recoveryKey) {
                $exportPath = "$env:USERPROFILE\BitLocker-$($volume.MountPoint.TrimEnd(':\'))-$(Get-Date -Format 'yyyyMMdd').txt"
                $recoveryKey.RecoveryPassword | Out-File -FilePath $exportPath -Force
                Write-Host "`nBitLocker recovery key exported to: $exportPath" -ForegroundColor Green
                Write-Host "Please save this key in a secure location." -ForegroundColor Yellow
            } else {
                Write-Host "No recovery key found for volume $($volume.MountPoint)." -ForegroundColor Yellow
                Write-Host "-----------------------------------------------" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "Error exporting BitLocker key: $_" -ForegroundColor Red
}

# Set DNS suffix
Write-Host "Setting DNS suffix to .quar.bris.ac.uk..." -ForegroundColor Yellow
try {
    Set-DnsClientGlobalSetting -SuffixSearchList @(".quar.bris.ac.uk")
    Write-Host "DNS suffix configured successfully." -ForegroundColor Green
} catch {
    Write-Host "Error setting DNS suffix: $_" -ForegroundColor Red
}

"Standalone completed. Log file: $logFile" | Write-Host
# End logging
Stop-Transcript
# End of script

