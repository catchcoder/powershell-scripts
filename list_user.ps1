# Script to list users who logged in this year on a Windows Server 2008 R2

$userProfiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.LastUseTime -like "*2025*" } | ForEach-Object { $_.LocalPath.Split('\')[-1] }

# Filter out lines containing "-a", "Network", or "Local"
$filteredArray = $userProfiles  | Where-Object { $_ -notmatch "-a|Network|Local" }

# Add the suffix "@bristol.ac.uk" to each username
$usernamesWithSuffix = $filteredArray | ForEach-Object { $_ + "@bristol.ac.uk" }

# Output the $usernamesWithSuffix array to a text file
$usernamesWithSuffix | out-file -FilePath "c:\temp\active_users_2025.txt"
