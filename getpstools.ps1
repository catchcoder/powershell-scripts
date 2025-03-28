# Define the URL for Sysinternals Suite and the destination folder
$sysinternalsUrl = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
$destinationFolder = "C:\SysinternalsSuite"
$zipFilePath = "$destinationFolder\SysinternalsSuite.zip"

# Create the destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder -Force
}

# Download the Sysinternals Suite zip file
Write-Host "Downloading Sysinternals Suite..."
Invoke-WebRequest -Uri $sysinternalsUrl -OutFile $zipFilePath

# Unpack the zip file to the destination folder
Write-Host "Unpacking Sysinternals Suite..."
Expand-Archive -Path $zipFilePath -DestinationPath $destinationFolder -Force

# Remove the zip file after extraction
Remove-Item -Path $zipFilePath -Force

Write-Host "Sysinternals Suite has been downloaded and unpacked to $destinationFolder."