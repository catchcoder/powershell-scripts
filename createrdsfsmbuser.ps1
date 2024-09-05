# createrdsfsmbuser.ps1
# version 20240905.01
# Author Chris Hawkins

Clear 

#Define value
$newusername = $env:COMPUTERNAME + "-smb"
$newuserpassword = (Read-Host -AsSecureString "Account $newuser password")

Write-Host " Create user $newusername ?`n`nPress y to confirm or any other key to cancel?"
    $reply = Read-Host
    if ($reply.ToLower() -eq 'y' -or $reply.ToLower() -eq 'yes') {
        #continue
    }
    else {
        Write-Host "Cencelled."
        continue
    }

# Start prcess
Write-Host "Creating new smb user $newusername"
Write-Host "`n"

# Splatting data
$NewUser = @{
    Name                     = $newusername
    Password                 = $newuserpassword
    FullName                 = $AccountFullName = "RDSF SMB Local User"
    Description              = $AccountDescription = "Local User Account for RDSF-Gateway"
    AccountNeverExpires      = $true
    PasswordNeverExpires     = $true
    UserMayNotChangePassword = $true
    }

## Add new user

New-LocalUser @NewUser
