# Require elevation
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
    Write-Warning "Please run this script as Administrator!"
    Exit 1
}

# Get all user profiles
$userProfiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { !$_.Special }

foreach ($profile in $userProfiles) {
    try {
        $profilePath = $profile.LocalPath
        $googleAppDataPath = Join-Path -Path $profilePath -ChildPath "AppData\Local\Google"
        
        if (Test-Path -Path $googleAppDataPath) {
            Write-Host "Removing Google AppData folder from: $profilePath"
            Remove-Item -Path $googleAppDataPath -Recurse -Force -ErrorAction Stop
            Write-Host "Successfully removed Google AppData folder from: $profilePath" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Failed to remove Google AppData folder from $profilePath : $_"
    }
}

Write-Host "Operation completed." -ForegroundColor Cyan