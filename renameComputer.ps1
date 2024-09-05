# renameComputer.ps1
# version 20240905.01
# Author Chris Hawkins

Clear

# Get current and enter new hostname
Write-Host "This computers hostname is: $env:COMPUTERNAME "
$newHostname = Read-Host -prompt "Enter new hostname: "

# Confirm hostanem change
$yn = Read-Host -prompt "Press Y to rename $newHostname this will restart the computer or any other key to cancel"
    if ($yn -eq "y" -or $yn -eq "Y") {
         Rename-Computer -NewName $newHostname -restart 
    }