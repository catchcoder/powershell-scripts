# Define the threshold date (1 year ago from today)
$thresholdDate = (Get-Date).AddYears(-1)

# Get all user profiles
$userProfiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false }

foreach ($profile in $userProfiles) {
    # Convert the LastUseTime to a DateTime object
    $lastUseTime = [Management.ManagementDateTimeConverter]::ToDateTime($profile.LastUseTime)

    # Check if the profile is older than the threshold date
    if ($lastUseTime -lt $thresholdDate) {
        Write-Host "Removing profile: $($profile.LocalPath) Last used: $lastUseTime"
        # Remove the user profile
        $profile.Delete()
    }
}