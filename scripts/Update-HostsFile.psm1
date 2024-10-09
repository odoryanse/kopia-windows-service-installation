function Update-HostsFile {
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$')]
        [string]$IPAddress,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Hostname
    )

    $hostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"

    if (-not (Test-Path -Path $hostsFilePath)) {
        throw "Hosts file not found."
    }

    $hostsFileContent = Get-Content -Path $hostsFilePath

    $entryPattern = "^\s*$IPAddress\s+$Hostname\s*(#.*)?$"

    $entryExists = $false
    foreach ($line in $hostsFileContent) {
        if ($line -match $entryPattern) {
            $entryExists = $true
            break
        }
    }

    if ($entryExists) {
        # Write-Host "The entry '$IPAddress $Hostname' already exists in the hosts file." -ForegroundColor Yellow
        return
    } else {
        # Add the new entry to the hosts file
        try {
            "$IPAddress`t$Hostname" | Out-File -FilePath $hostsFilePath -Append -Encoding ASCII
            # Write-Host "Successfully added '$IPAddress $Hostname' to the hosts file." -ForegroundColor Green
            return
        } catch {
            throw "Error occurred while writing to the hosts file: $_"
        }
    }
}
