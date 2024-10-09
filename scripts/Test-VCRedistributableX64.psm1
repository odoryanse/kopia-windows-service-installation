function Test-VCRedistributableX64 {
    $redistributableName = "Microsoft Visual C++"
    
    $installed = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '$redistributableName%'" |
                 Where-Object { $_.Name -like "*x64*" }

    if ($installed.Count -gt 0) {
        Write-Host "The following Microsoft Visual C++ Redistributable x64 versions are installed:"
        foreach ($item in $installed) {
            Write-Host "$($item.Name) - Version: $($item.Version)"
        }
        return $true
    } else {
        Write-Host "No Microsoft Visual C++ Redistributable x64 versions found."
        return $false
    }
}
