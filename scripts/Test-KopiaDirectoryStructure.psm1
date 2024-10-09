function Test-KopiaDirectoryStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$basePath
    )

    $paths = @{
        BasePath     = $basePath
        ToolsPath    = Join-Path $basePath 'tools'
        ConfigPath   = Join-Path $basePath 'configs'
        OpenSSLPath  = Join-Path $basePath 'tools\openssl'
        TLSPath      = Join-Path $basePath 'configs\certs'
        LogPath      = Join-Path $basePath 'logs'
        CachePath    = Join-Path $basePath 'cache'
    }

    foreach ($key in $paths.Keys) {
        if (-not (Test-Path $paths[$key] -PathType Container)) {
            try {
                New-Item -Path $paths[$key] -ItemType Directory -Force | Out-Null
            } catch {
                throw "Failed to create directory: $($paths[$key])"
            }
        }
    }

    return $paths
}
