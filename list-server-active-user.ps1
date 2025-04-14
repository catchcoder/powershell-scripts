# Script to list users who logged in this year on a Windows Server 2008 R2

# Check if the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an Administrator." -ErrorAction Stop
    exit
}

# Create the temp directory if it doesn't exist 
if (-not (Test-Path -Path "c:\temp")) {
    New-Item -ItemType Directory -Path "c:\temp" -Force
}

# Define output file path
$outputFile = "c:\temp\active_users_2024.txt"

#remove the file if it exists
Remove-Item -Path $outputFile -ErrorAction SilentlyContinue

# get user profiles that have logged in this year
$userProfiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.LastUseTime -like "*2024*" } | ForEach-Object { $_.LocalPath.Split('\')[-1] }

# Filter out lines containing "-a", "Network", or "Local"
$filteredArray = $userProfiles  | Where-Object { $_ -notmatch "-a|Network|Local" }

# Add the suffix "@bristol.ac.uk" to each username
$usernamesWithSuffix = $filteredArray | ForEach-Object { $_ + "@bristol.ac.uk" }

# sort the array of usernames with suffix
$usernamesWithSuffix = $usernamesWithSuffix | Sort-Object 

# Output the $usernamesWithSuffix array to a text file
$usernamesWithSuffix | Out-File -FilePath $outputFile
