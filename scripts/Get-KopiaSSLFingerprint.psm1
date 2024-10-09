function Get-KopiaSSLFingerprint {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Paths
    )

    try {
        & "$($paths.OpenSSLPath)\openssl.exe" x509 -noout -fingerprint -sha256 -inform pem -in "$($paths.TLSPath)\kopia.crt" `
            | Tee-Object -Variable sha256_output | Out-Null
        $sha256_output = $sha256_output | ForEach-Object { $_ -split "=" } | Select-Object -Last 1
        
        if ($sha256_output) {
            $sha256_output = $sha256_output.Trim()
            Set-Content -Path "$($paths.TLSPath)\SHA256.txt" -Value "SERVER CERT SHA256: $sha256_output"
            Write-Host "- SHA256 Fingerprint: " -NoNewLine
            Write-Host "$sha256_output" -ForegroundColor Green
            Write-Host "- Saved to: $($paths.TLSPath)\SHA256.txt"
            return $sha256_output
        } else {
            throw "Unable to generate SHA256 fingerprint."
        }
    } catch {
        throw $_.Exception.Message
    }
}