function New-RcloneRemote {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Paths
    )
    try {
        $rclonePath = $Paths.RclonePath
        $rcloneConfigPath = $Paths.RcloneConfigPath

        Write-Host "The script will now run the " -NoNewLine
        Write-Host "rclone config " -NoNewLine -ForegroundColor DarkYellow
        Write-Host "command for you to set up your remote configuration."
        Write-Host "Please choose " -NoNewLine
        Write-Host "`"q) Quit config`" " -NoNewLine -ForegroundColor DarkYellow
        Write-Host "once you are done to return.`n"

        Write-Host "Rclone Path        : $rclonePath"
        Write-Host "Rclone Config Path : $rcloneConfigPath`n"

        if (-not $rcloneConfigPath -or -not (Test-Path -Path $rcloneConfigPath)) {
            New-Item -Path $rcloneConfigPath -ItemType File | Out-Null
        }

        Start-Process -FilePath "$rclonePath" `
            -ArgumentList "config", "--config", "`"$rcloneConfigPath`"" `
            -NoNewWindow -Wait

        & $rclonePath listremotes --config "`"$rcloneConfigPath`"" `
            | Tee-Object -Variable remoteList | Out-Null

        if (-not $remoteList) {
            throw "No remotes found. Please configure at least one remote."
        }

        return $remoteList
    } catch {
        throw $_.Exception.Message
    }
    
}