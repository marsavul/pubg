# Registry keys to search
$registryKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\ShowJumpView",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched",
    "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules",
    "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
)

# Regex to extract path from drive letter up to steamapps\common
$pathRegex = '(?i)([A-Z]:\\[^"]*?steamapps\\common)'

# File patterns to delete
$deletePatterns = @("LicenseScreen*.*", "LoadingScreen*.*")

# Tracking folders and deleted files
$moviesFolders = @()
$deletedFiles = @()

# Search all registry keys
foreach ($regPath in $registryKeys) {
    try {
        $regProps = Get-ItemProperty -Path $regPath -ErrorAction Stop
    } catch {
        continue
    }

    $regNames  = $regProps.PSObject.Properties | ForEach-Object { $_.Name }
    $regValues = $regProps.PSObject.Properties | ForEach-Object { $_.Value }

    foreach ($entry in ($regNames + $regValues)) {
        if ($entry -is [string] -and $entry -match $pathRegex) {
            $commonPath = $matches[1]
            if (-not $commonPath.EndsWith("\")) {
                $commonPath += "\"
            }

            $moviesPath = Join-Path $commonPath "PUBG\TslGame\Content\Movies"
            $moviesFolders += $moviesPath
        }
    }
}

# If no registry paths were found, prompt the user
if ($moviesFolders.Count -eq 0) {
    Write-Host ""
    Write-Host "No PUBG installation path was found in the registry."
    Write-Host ""
    Write-Host "Please follow these instructions to locate the game folder:"
    Write-Host "1. Open Steam"
    Write-Host "2. Right click on the game and go to 'Properties...'"
    Write-Host "3. Go to 'Installed Files' and click 'Browse...' on the right-hand side"
    Write-Host "4. In File Explorer, right click on the explorer bar and choose 'Copy Address'"
    Write-Host ""

    $userInput = Read-Host "Paste the folder path to PUBG (it should end in ...\PUBG)"

    if ($userInput -and (Test-Path $userInput)) {
        $manualMoviesPath = Join-Path $userInput "TslGame\Content\Movies"
        $moviesFolders += $manualMoviesPath
    } else {
        Write-Host ""
        Write-Host "Invalid path provided. Continuing..."
    }
}

# Remove duplicates
$moviesFolders = $moviesFolders | Sort-Object -Unique

# Delete files in Movies folders
foreach ($folder in $moviesFolders) {
    if (Test-Path $folder) {
        foreach ($pattern in $deletePatterns) {
            $files = Get-ChildItem -Path $folder -Filter $pattern -File -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    Remove-Item $file.FullName -Force -ErrorAction Stop
                    $deletedFiles += $file.FullName
                } catch {}
            }
        }
    }
}

# Output results
if ($deletedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "The following files were found and removed:"
    Write-Host ""
    $deletedFiles | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "No files were found."
}

Write-Host ""
Write-Host "Press Enter to exit..."
[void][System.Console]::ReadLine()
