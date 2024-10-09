function Update-TlsConf_AltNames {
    param (
        [hashtable]$Paths,
        [hashtable]$NewDnsEntries
    )

    $ConfigFilePath = "$($Paths.TLSPath)\openssl-domain.ext"
    if (-not (Test-Path -Path $ConfigFilePath)) {
        throw "Configuration file not found at path: $ConfigFilePath"
    }

    $fileContent = Get-Content -Path $ConfigFilePath
    
    $inAltNamesSection = $false
    $updatedContent = @()

    foreach ($line in $fileContent) {
        if ($line -match '^\[ alt_names \]') {
            $inAltNamesSection = $true
            $updatedContent += $line
            continue
        }

        if ($inAltNamesSection -and $line -match '^\[') {
            $inAltNamesSection = $false
        }

        if ($inAltNamesSection -and $line -match '^DNS\.\d+\s*=') {
            if ($line -notmatch '^\s*#') {
                $dnsIndex = [regex]::Match($line, 'DNS\.(\d+)').Groups[1].Value
                if ($NewDnsEntries.ContainsKey("DNS.$dnsIndex")) {
                    $newDnsEntry = "DNS.$dnsIndex = $($NewDnsEntries["DNS.$dnsIndex"])"
                    $updatedContent += $newDnsEntry
                    continue
                }
            }
        }

        $updatedContent += $line
    }
    Set-Content -Path $ConfigFilePath -Value $updatedContent
    # Write-Host "The DNS entries have been updated successfully." -ForegroundColor Green
    return
}
