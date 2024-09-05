# renameComputer.ps1
# version 20240905.01
# Author Chris Hawkins

Clear
Write-Host "This computers hostname is: $env:COMPUTERNAME "
$newName = Read-Host -prompt "Enter new hostname: "
$yn = Read-Host -prompt "Press Y to rename $newName or any other key to cancel"
    if ($yn -eq "y" -or $yn -eq "Y") {
         Rename-Computer -NewName $newName -Restart 
    }