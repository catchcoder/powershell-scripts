<#
.SYNOPSIS
    Converts a Windows 10 machine from a domain-joined configuration to a standalone system, performing essential configuration and cleanup tasks.

.DESCRIPTION
    This script automates the process of transitioning a Windows 10 computer from a domain environment to a standalone setup. It performs the following actions:
    - Confirms user intent before proceeding.
    - Starts a transcript log for auditing.
    - Checks for required PowerShell version and administrative privileges.
    - Sets and activates a Windows MAK key.
    - Modifies local password policies for simplified management.
    - Creates new local standard and administrator user accounts.
    - Enables and configures the built-in Administrator account.
    - Removes Office 365 if present.
    - Configures the Security Event Log to overwrite as needed.
    - Exports BitLocker recovery keys for all fully encrypted volumes.
    - Blocks Microsoft consumer account authentication.
    - Adds default system accounts to the local 'Users' group.
    - Hides the Administrator account from the login screen.
    - Download and installs LibreOffice.
    - Removes the computer from the domain using provided credentials.
    - Displays next steps for the user, including BitLocker key management and network changes.

.USAGE
    1. Run this script in an elevated PowerShell 64bit session (Run as Administrator).
    2. Ensure you have made necessary changes to the script variables, such as the Windows MAK key and passwords for local accounts.
    3. Follow the prompts to confirm the operation and provide necessary credentials.
    4. Review the log file generated in the TEMP directory for details of the actions performed.
    5. After completion, follow the displayed next steps to finalize the standalone configuration.

.NOTES
    - Internet access is required for downloading LibreOffice and other online resources.
    - Ensure you have backups of important data before running this script.
    - Replace placeholder MAK keys and passwords with your organization's actual values before use.
    - The script requires PowerShell 5.0 or later.
    - Some actions (such as domain removal and BitLocker key export) may require additional permissions.
    - Test this script in a non-production environment before deploying widely.
    - Author: Chris Hawkins - Academic Applications Team
    - Version: 1.0.5
    - Date: 3/7/2025
#>
# Requires elevation (Run as Administrator)
#Requires -RunAsAdministrator

# Script Configuration Section
# =========================

# Microsoft Activation Key
$script:windowsMakKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" # Replace with actual MAK key

# Passwords for local accounts
$script:administratorPassword = "Jumper-mistook-rewarded?" # Change this to your desired password
$script:userPassword = "Password1234!" # Change this to your desired password
$script:adminPassword = "Password1234!" # Change this to your desired password

# Use the latest known direct download link from Microsoft
$script:officeDownloadUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18827-20140.exe"
# Define the LibreOffice download URL
$script:libreOfficeUrl = "https://download.documentfoundation.org/libreoffice/stable/25.2.4/win/x86_64/LibreOffice_25.2.4_Win_x86-64.msi"

if (-not [Environment]::Is64BitProcess) {
    Write-Host "This script must be run in a 64-bit PowerShell environment." -ForegroundColor Red
    exit
}


function Confirm-StandaloneConversion {
    Write-Host "This script will convert the current machine to a standalone system." -ForegroundColor Yellow
    $confirmation = Read-Host -Prompt 'Do you wish to continue? type y and enter to continue or n to cancel)'
    if ($confirmation.ToLower() -ne "yes" -and $confirmation.ToLower() -ne "y") {
        Write-Host "Operation cancelled by user." -ForegroundColor Red
        Pause
        exit
    }
    Write-Host "IMPORTANT: Before running this script, ensure you have updated the Windows MAK key and all local account passwords in the configuration section above." -ForegroundColor Red
    Write-Host "Failure to do so may result in incorrect activation or insecure accounts." -ForegroundColor Red
    if ($script:windowsMakKey -eq "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX") {
        Write-Host "ERROR: Please update the Windows MAK key in the configuration section before running this script." -ForegroundColor Red
        Pause
        exit
    }
}

function Start-Logging {
    $global:logFile = Join-Path $env:TEMP "windows-standalone-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    Start-Transcript -Path $logFile -Append
    Write-Host "Log file created at: $logFile"
}

function Check-Prerequisites {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "This script requires PowerShell 5 or later. Current version: $($PSVersionTable.PSVersion)" -ErrorAction Stop
    }
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "This script must be run as an Administrator." -ErrorAction Stop
    }
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force
}

function Set-WindowsMAK {
    Write-Host "Configuring Windows MAK key and activating..." -ForegroundColor Yellow
    try {
        $result = Invoke-Expression "cscript //nologo `"$env:windir\system32\slmgr.vbs`" /ipk $script:windowsMakKey"
        Write-Host $result -ForegroundColor Green
        $activation = Invoke-Expression "cscript //nologo `"$env:windir\system32\slmgr.vbs`" /ato"
        Write-Host $activation -ForegroundColor Green
        Write-Host "Windows MAK configuration and activation completed." -ForegroundColor Green
    }
    catch {
        Write-Host "Error configuring Windows MAK: $_" -ForegroundColor Red
    }
}

function Set-PasswordPolicy {
    Write-Host "Modifying password policy..." -ForegroundColor Yellow
    try {
        net accounts /maxpwage:unlimited
        net accounts /minpwage:0
        net accounts /minpwlen:0
        net accounts /uniquepw:0
        secedit /export /cfg C:\secpol.cfg
        (Get-Content C:\secpol.cfg).Replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
        secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
        Remove-Item -Path C:\secpol.cfg -Force
        Write-Host "Password policy modified successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error modifying password policy: $_" -ForegroundColor Red
    }
}

function Create-LocalUsers {
    Write-Host "Creating local standard and admin user accounts..." -ForegroundColor Yellow
    try {
        $hostname = $env:COMPUTERNAME
        $standardUser = "$hostname-user"
        $adminUser = "$hostname-admin"
        # Create standard user
        if (Get-LocalUser -Name $standardUser -ErrorAction SilentlyContinue) {
            Write-Host "Standard user account '$standardUser' already exists." -ForegroundColor Yellow
            return
        }
        Write-Host "Creating local standard user account..." -ForegroundColor Yellow
        $secureUserPassword = ConvertTo-SecureString $script:userPassword -AsPlainText -Force
        New-LocalUser -Name $standardUser -Password $secureUserPassword -FullName $standardUser -Description "Standard User Account" -PasswordNeverExpires
        Add-LocalGroupMember -Group "Users" -Member $standardUser
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $standardUser
        
        # create admin user
        if (Get-LocalUser -Name $adminUser -ErrorAction SilentlyContinue) {
            Write-Host "Admin user account '$adminUser' already exists." -ForegroundColor Yellow
            return
        }
        Write-Host "Creating local administrator account..." -ForegroundColor Yellow    
        $secureAdminPassword = ConvertTo-SecureString $script:adminPassword -AsPlainText -Force
        New-LocalUser -Name $adminUser -Password $secureAdminPassword -FullName $adminUser -Description "Admin User Account" -PasswordNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $adminUser
    }
    catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
}

function Enable-LocalAdmin {
    Write-Host "Enabling and configuring local administrator account..." -ForegroundColor Yellow
    try {
        $securePassword = ConvertTo-SecureString $script:administratorPassword -AsPlainText -Force
        Enable-LocalUser -Name "Administrator"
        Set-LocalUser -Name "Administrator" -Password $securePassword
        Write-Host "Local Administrator account enabled" -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
}



function Hide-AdministratorAccount {
    Write-Host "Hiding the Administrator account from the login screen..." -ForegroundColor Yellow
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
        if (-not (Test-Path $regPath)) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts" -Name "UserList" -Force | Out-Null
        }
        New-ItemProperty -Path $regPath -Name "Administrator" -PropertyType DWord -Value 0 -Force
        Write-Host "Administrator account has been hidden from the login screen." -ForegroundColor Green
    }
    catch {
        Write-Host "Error hiding Administrator account: $_" -ForegroundColor Red
    }
}


function Add-DefaultUsersToUsersGroup {
    Write-Host "Adding default system accounts to 'Users' group..." -ForegroundColor Yellow
    try {
        Add-LocalGroupMember -Group "Users" -Member "NT AUTHORITY\INTERACTIVE"
        Add-LocalGroupMember -Group "Users" -Member "NT AUTHORITY\Authenticated Users"
        # Verify the users have been added
        $groupMembers = Get-LocalGroupMember -Group "Users" | Select-Object -ExpandProperty Name
        if ($groupMembers -contains "NT AUTHORITY\INTERACTIVE" -and $groupMembers -contains "NT AUTHORITY\Authenticated Users") {
            Write-Host "Default system accounts added to 'Users' group successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Verification failed: One or both accounts not found in 'Users' group." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error adding default system accounts to 'Users' group: $_" -ForegroundColor Red
    }
}

function Remove-Office365 {
    Write-Host "Removing Office 365..." -ForegroundColor Yellow
    try {
        # Define variables
        $tempPath = [System.IO.Path]::GetTempPath()
        $extractPath = Join-Path $tempPath "ODT"
        $installerPath = Join-Path $tempPath "OfficeDeploymentTool.exe"

        # Create extract directory if it doesn't exist
        if (-not (Test-Path $extractPath)) {
            New-Item -ItemType Directory -Path $extractPath | Out-Null
        }

        # Download the installer
        Invoke-WebRequest -Uri $script:officeDownloadUrl -OutFile $installerPath

        # Run the installer silently to extract files
        Start-Process -FilePath $installerPath -ArgumentList "/quiet /extract:$extractPath" -Wait

        # Output result
        Write-Host "ODT extracted to: $extractPath"

        ##################

        # Define the XML content
        $xmlContent = '<Configuration><Remove><Product ID="O365ProPlusRetail" /></Remove><Display Level="None" AcceptEULA="TRUE" /></Configuration>'


        # Define the full path to the configuration file
        $configFilePath = Join-Path $extractPath "configuration.xml"

        # Write the content to the file
        $xmlContent | Out-File -FilePath $configFilePath 

        # Output the path
        Write-Host "configuration.xml created at: $configFilePath"

        #################

        # Define paths
        $SetupExe = Join-Path $extractPath "setup.exe"
        $ConfigPath = Join-Path $extractPath "configuration.xml"
        # Run the Office Deployment Tool with the configuration file
        Start-Process -FilePath $SetupExe -ArgumentList "/configure `"$ConfigPath`"" -Wait

    }
    catch {
        Write-Host "Error removing Office 365: $_" -ForegroundColor Red
    }
}

function Configure-EventLog {
    Write-Host "Configuring Security Event Log - Overwrite as needed..." -ForegroundColor Yellow
    try {
        wevtutil set-log Security /retention:false
        Write-Host "Security Event Log configured to overwrite as needed." -ForegroundColor Green
    }
    catch {
        Write-Host "Error configuring Security Event Log: $_" -ForegroundColor Red
    }
}

function Export-BitLockerKey {
    Write-Host "Exporting BitLocker recovery key..." -ForegroundColor Yellow
    try {
        $volumes = Get-BitLockerVolume
        foreach ($volume in $volumes) {
            if ($volume.VolumeStatus -eq "FullyEncrypted") {
                $recoveryKey = $volume | Select-Object -ExpandProperty KeyProtector | 
                Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
                if ($recoveryKey) {
                    $exportPath = "$env:USERPROFILE\$env:COMPUTERNAME-BitLocker-$($volume.MountPoint.TrimEnd(':\'))-$(Get-Date -Format 'yyyyMMdd').txt"
                    $recoveryKey.RecoveryPassword | Out-File -FilePath $exportPath -Force
                    Write-Host "`nBitLocker recovery key exported to: $exportPath" -ForegroundColor Green
                    Write-Host "Please save this key in a secure location." -ForegroundColor Yellow
                }
                else {
                    Write-Host "No recovery key found for volume $($volume.MountPoint)." -ForegroundColor Yellow
                }
            }
        }
        Start-Process explorer.exe $env:USERPROFILE
    }
    catch {
        Write-Host "Error exporting BitLocker key: $_" -ForegroundColor Red
    }
}

function Block-MicrosoftAccounts {
    Write-Host "Block all consumer Microsoft user account authentication..." -ForegroundColor Yellow
    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $registryKey = "NoConnectedUser"
        $registryValue = 3
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force
        }
        Set-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue
        Write-Host "The 'NoConnectedUser' registry key has been set to 3 to block Microsoft account sign-in and creation."
    }
    catch {
        Write-Host "Error configuring Microsoft account policy: $_" -ForegroundColor Red
    }
}

function Add-DefaultUsersToUsersGroup {
    Write-Host "Adding default system accounts to 'Users' group..." -ForegroundColor Yellow
    try {
        $groupMembers = Get-LocalGroupMember -Group "Users" | Select-Object -ExpandProperty Name
        if (-not ($groupMembers -contains "NT AUTHORITY\INTERACTIVE")) {
            Write-Host "Adding 'NT AUTHORITY\INTERACTIVE' to 'Users' group..." -ForegroundColor Yellow
            #Invoke-Expression 'net localgroup "Users" "NT AUTHORITY\INTERACTIVE" /add'
            
            Add-LocalGroupMember -Group "Users" -Member "NT AUTHORITY\INTERACTIVE"
        } else {
            Write-Host "'NT AUTHORITY\INTERACTIVE' is already a member of 'Users' group." -ForegroundColor Yellow
        }

        if (-not ($groupMembers -contains "NT AUTHORITY\Authenticated Users")) {
            write-Host "Adding 'NT AUTHORITY\Authenticated Users' to 'Users' group..." -ForegroundColor Yellow

            #Invoke-Expression 'net localgroup "Users" "NT AUTHORITY\Authenticated Users" /add'

            Add-LocalGroupMember -Group "Users" -Member "NT AUTHORITY\Authenticated Users"
        } else {
            Write-Host "'NT AUTHORITY\Authenticated Users' is already a member of 'Users' group." -ForegroundColor Yellow
        }
        # Verify the users have been added
        $groupMembers = Get-LocalGroupMember -Group "Users" | Select-Object -ExpandProperty Name
        if ($groupMembers -contains "NT AUTHORITY\INTERACTIVE" -and $groupMembers -contains "NT AUTHORITY\Authenticated Users") {
            Write-Host "Default system accounts added to 'Users' group successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Verification failed: One or both accounts not found in 'Users' group." -ForegroundColor Red
        }

        # Add 'UOB\Domain Users' back to the local 'Users' group if it exists
        try {
            $groupMembers = Get-LocalGroupMember -Group "Users" | Select-Object -ExpandProperty Name
            if (-not ($groupMembers -contains "UOB\Domain Users")) {
                write-Host "Adding 'UOB\Domain Users' to 'Users' group..." -ForegroundColor Yellow

                Add-LocalGroupMember -Group "Users" -Member "UOB\Domain Users" -ErrorAction Stop
            } else {
                Write-Host "'UOB\Domain Users' is already a member of 'Users' group." -ForegroundColor Yellow
            }
            # Check if 'UOB\Domain Users' was successfully added
            $groupMembers = Get-LocalGroupMember -Group "Users" | Select-Object -ExpandProperty Name
            if ($groupMembers -contains "UOB\Domain Users") {
                Write-Host "'UOB\Domain Users' has been added to the 'Users' group." -ForegroundColor Green
            } else {
                Write-Host "Failed to add 'UOB\Domain Users' to the 'Users' group." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Could not add 'UOB\Domain Users' to 'Users' group (it may not exist): $_" -ForegroundColor Yellow
        }

    }
    catch {
        Write-Host "Error adding default system accounts to 'Users' group: $_" -ForegroundColor Red
    }
}

function Install-LibreOffice {
    Write-Host "Downloading and installing LibreOffice 25.2.4..." -ForegroundColor Yellow
    try {
        $installerPath = "$env:TEMP\LibreOffice.msi"
        Write-Host "Downloading LibreOffice from $libreOfficeUrl" -ForegroundColor Yellow
        Invoke-WebRequest -Uri $script:libreOfficeUrl -OutFile $installerPath
        Start-Process "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait
        Remove-Item $installerPath -Force
        Write-Host "LibreOffice installation completed." -ForegroundColor Green
    }
    catch {
        Write-Host "Error downloading or installing LibreOffice: $_" -ForegroundColor Red
    }
}

function Remove-FromDomain {
    Write-Host "Removing computer from domain..." -ForegroundColor Yellow
    try {
        Write-Host "Please provide your UoB login credentials to remove the computer from the domain." -ForegroundColor Yellow
        $credential = Get-Credential -Message "Enter UoB credentials"
        Remove-Computer -UnjoinDomainCredential $credential -Force -PassThru   
    }
    catch {
        Write-Host "Error removing computer from domain: $_" -ForegroundColor Red
    }
}

function Launch-ComputerManagement {
    Write-Host "Launching Computer Management (compmgmt.msc)..." -ForegroundColor Yellow
    try {
        # Launch Computer Management and select the Users group
        Start-Process "compmgmt.msc"
        # Additionally, display the members of the 'Users' group in the console
        Write-Host "`nMembers of the 'Users' group:" -ForegroundColor Cyan
        try {
            Get-LocalGroupMember -Group "Users" | Select-Object -ExpandProperty Name | ForEach-Object { Write-Host " - $_" }
        }
        catch {
            Write-Host "Unable to list 'Users' group members: $_" -ForegroundColor Red
        }
        Write-Host "Computer Management launched." -ForegroundColor Green
    }
    catch {
        Write-Host "Error launching Computer Management: $_" -ForegroundColor Red
    }
}


function Show-NextSteps {
    Write-Host "`nIMPORTANT NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "1. Copy the exported BitLocker recovery keys to your KeePass vault for secure storage." -ForegroundColor Yellow
    Write-Host "2. Move the computer's MAC address registration in NETREG from the campus network to the Quarantine Network." -ForegroundColor Yellow
    Write-Host "   This is necessary to prevent the computer from attempting to connect to the campus network." -ForegroundColor Yellow
    Write-Host "3. Verify in Computer Management that'NT AUTHORITY\\Authenticated Users' and 'NT AUTHORITY\\INTERACTIVE' have been added to the local 'Users' group." -ForegroundColor Cyan
    Write-Host "4. Restart the computer to complete the transition to standalone mode." -ForegroundColor Yellow
    "Standalone completed. Log file: $logFile" | Write-Host
}

# Main script execution
Confirm-StandaloneConversion
Start-Logging
Check-Prerequisites
Set-WindowsMAK
Set-PasswordPolicy
Create-LocalUsers
Enable-LocalAdmin
Hide-AdministratorAccount
Add-DefaultUsersToUsersGroup
Remove-Office365
Configure-EventLog
Export-BitLockerKey
Block-MicrosoftAccounts
Install-LibreOffice # Comment this line if no internet access is available
Remove-FromDomain # Comment this line for testing
Launch-ComputerManagement
Show-NextSteps
Stop-Transcript
