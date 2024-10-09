function New-KopiaRootCA {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Paths
    )

    try {
        & "$($paths.OpenSSLPath)\openssl.exe" genrsa -out "$($paths.TLSPath)\kopia.ca.key" 2048 > $null 2>&1
        & "$($paths.OpenSSLPath)\openssl.exe" req -x509 -new -nodes `
            -key "$($paths.TLSPath)\kopia.ca.key" -sha256 -days 3650 `
            -out "$($paths.TLSPath)\kopia.ca.pem" -config "$($paths.TLSPath)\openssl-ca.conf" > $null 2>&1

        if (Test-Path "$($paths.TLSPath)\kopia.ca.pem") {
            Write-Host "- Root CA certificate created successfully!" -ForegroundColor DarkGreen
            Write-Host "- Saved to: $($paths.TLSPath)\kopia.ca.pem"
            return "$($paths.TLSPath)\kopia.ca.pem"
        } else {
            throw "The Root CA certificate was not created. Please check file permissions or configuration."
        }
    } catch {
        throw $_.Exception.Message
    }
}