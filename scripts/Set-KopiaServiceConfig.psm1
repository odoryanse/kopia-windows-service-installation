function Set-KopiaServiceConfig {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Paths,
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [string]$Name = $null,
        [hashtable]$Address = $null,
        [string]$WebUIUsername = $null,
        [bool]$Insecure = $false,
        [string]$Description = "Kopia - Fast and Secure Open-Source Backup Software",
        [hashtable[]]$Env = $null,
        [string[]]$Arguments = $null
    )

    $serviceYamlPath = "$($Paths.ConfigPath)\$Id-winsw.yml"

    $fileContent = @()

    $fileContent += "id: $Id"
    $fileContent += "executable: '$($Paths.BasePath)\kopia.exe'"
    $fileContent += "startMode: Automatic"
    $fileContent += "workingdirectory: '$($Paths.BasePath)'"

    if ($Name) {
        $fileContent += "name: $Name"
    } else {
        $fileContent += "name: $Id"
    }

    if ($Description) {
        $fileContent += "description: $Description"
    }

    if ($Env) {
        $fileContent += "env:"
        foreach ($envVar in $Env) {
            $fileContent += "  - name: $($envVar.name)"
            $fileContent += "    value: $($envVar.value)"
        }
    }
    
    $fileContent += "arguments: >"
    $serviceArgs = @(
            "server start", 
            "--config-file `"$($Paths.ConfigPath)\repository.config`"", 
            "--log-dir `"$($Paths.LogPath)`"", 
            "--cache-directory `"$($Paths.CachePath)`"", 
            "--address $($Address.IP):$($Address.Port)"
    )
    if ($insecure) {
        $serviceArgs += @(
            "--insecure",
            "--without-password"
        )
    } else {
        $serviceArgs += @(
            "--server-username `"$WebUIUsername`"",
            "--htpasswd-file `"$($Paths.ConfigPath)\htpasswd`"",
            "--tls-cert-file `"$($Paths.TLSPath)\kopia.crt`"",
            "--tls-key-file `"$($Paths.TLSPath)\kopia.key`""
        )
    }
    if ($Arguments) {
        $serviceArgs += $Arguments
    }
    foreach ($arg in $serviceArgs) {
        $fileContent += "    $arg"
    }

    if ($Paths.LogPath) {
        $fileContent += "log:"
        $fileContent += "    logpath: '$($Paths.LogPath)'"
        $fileContent += "    mod: append"
    }

    Set-Content -Path $serviceYamlPath -Value $fileContent -Force
}
