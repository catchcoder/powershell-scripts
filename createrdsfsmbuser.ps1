# createrdsfsmbuser.ps1
# version 20240905.01
# Author Chris Hawkins

#Define value
$newusername = $env:COMPUTERNAME + "-smb"
$newuserpassword = (Read-Host -AsSecureString "Account $newuser password")

Write-Host "Is the hostname '$env:computername' set correctly to the service tag? Press y to confirm user account or n to cancel?"
    $reply = Read-Host
    if ($reply.ToLower() -eq 'y' -or $reply.ToLower() -eq 'yes') {
        write-host "continyue"
        continue
    }
    else {
        Write-Host "exit"
        exit
    }

$NewUser = @{
    Name                     = $newusername
    Password                 = $newuserpassword
    FullName                 = $AccountFullName = "RDSF SMB Local User"
    Description              = $AccountDescription = "Local User Account for RDSF-Gateway"
    AccountNeverExpires      = $true
    PasswordNeverExpires     = $true
    UserMayNotChangePassword = $true
    }

# Start prcess
Clear
Write-Host "`n"
Write-Host "Adding new user $newusername"
Write-Host "----------------------------"
Write-Host "`n"

# Add new user
New-LocalUser @NewUser