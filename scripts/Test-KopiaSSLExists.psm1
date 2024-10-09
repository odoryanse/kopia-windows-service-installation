function Test-KopiaSSLExists {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Paths
    )

    try {
        if (-not (Test-Path "$($paths.TLSPath)\kopia.ca.pem")) {
            return $false
        }
        if (-not (Test-Path "$($paths.TLSPath)\kopia.ca.key")) {
            return $false
        }
        if (-not (Test-Path "$($paths.TLSPath)\kopia.crt")) {
            return $false
        }
        if (-not (Test-Path "$($paths.TLSPath)\kopia.key")) {
            return $false
        }

        return $true
    } catch {
        throw $_.Exception.Message
    }
}