function New-KopiaSSL {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Paths
    )
    try {
        & "$($paths.OpenSSLPath)\openssl.exe" genrsa -out "$($paths.TLSPath)\kopia.key" 2048 > $null 2>&1
        & "$($paths.OpenSSLPath)\openssl.exe" req -new `
            -out "$($paths.TLSPath)\kopia.csr" `
            -key "$($paths.TLSPath)\kopia.key" `
            -config "$($paths.TLSPath)\openssl-domain.conf" > $null 2>&1

        & "$($paths.OpenSSLPath)\openssl.exe" x509 -req `
            -in "$($paths.TLSPath)\kopia.csr" `
            -CA "$($paths.TLSPath)\kopia.ca.pem" `
            -CAkey "$($paths.TLSPath)\kopia.ca.key" `
            -CAcreateserial `
            -out "$($paths.TLSPath)\kopia.crt" `
            -days 3650 -sha256 `
            -extfile "$($paths.TLSPath)\openssl-domain.ext" > $null 2>&1

        if (Test-Path "$($paths.TLSPath)\kopia.crt") {
            Write-Host "- SSL certificate created successfully!" -ForegroundColor DarkGreen
            Write-Host "- Private Key saved to: '$($paths.TLSPath)\kopia.key'"
            Write-Host "- Certificate saved to: $($paths.TLSPath)\kopia.crt'"
            return @(
                "$($paths.TLSPath)\kopia.key",
                "$($paths.TLSPath)\kopia.crt"
            )
        } else {
            throw "The SSL certificate file was not created. Check for file system permissions and retry."
        }
    } catch {
        throw $_.Exception.Message
    }
}