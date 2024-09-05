# createrdsfsmbuser.ps1
# version 20240905.01
# Author Chris Hawkins
# Requires -Version 5

Clear 

# Define values
$newusername = $env:COMPUTERNAME + "-smb"
$newuserpassword = (Read-Host -AsSecureString "Account $newusername password")

# Start process
Write-Host "Creating new RDSF smb user $newusername"
Write-Host "`n"

# Splatting data
$NewUser = @{
    Name                     = $newusername
    Password                 = $newuserpassword
    FullName                 = $AccountFullName = "RDSF Local User $newusername"
    Description              = $AccountDescription = "Local User Account for RDSF-Gateway"
    AccountNeverExpires      = $true
    PasswordNeverExpires     = $true
    UserMayNotChangePassword = $true
    }

## Add new user
New-LocalUser @NewUser -confirm

## Add to Users Group
Add-LocalGroupMember -Group "Users" -Member $newusername -confirm
