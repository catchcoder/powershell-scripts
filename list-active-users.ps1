# Specify the remote server name
$server = "its-zdquar.cse.bris.ac.uk"

# Establish a remote session
Enter-PSSession -ComputerName $server

# Get currently logged in users via quser command
$users = quser 2>$null | ForEach-Object {
    $line = $_.Trim() -replace '\s+', ' '
    $items = $line.Split(' ')
    if ($items[0] -ne "USERNAME") {
        [PSCustomObject]@{
            Username = $items[0]
            SessionName = $items[1]
            State = $items[3]
            IdleTime = $items[4]
            LogonTime = $items[5..($items.Count-1)] -join ' '
        }
    }
}

# Display results
$users | Format-Table -AutoSize

# Exit the remote session
Exit-PSSession