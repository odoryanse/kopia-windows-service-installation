function Get-RepositoryPath {
    param (
        [array]$RemoteList,
        [hashtable]$Paths
    )

    try {
        $selection = @()
        Write-Host "Enter the number of the remote to use"
        Write-Host "List of remotes: `n"
        for ($i = 0; $i -lt $remoteList.Count; $i++) {
            $selection += "$($i + 1)"
            $remoteName = $remoteList[$i].Replace(":", "")
            Write-Host "$($i + 1). $remoteName"
        }
        Write-Host
        Get-UserChoice -Prompt "Select the number corresponding to your choice" -Options $selection `
            | Tee-Object -Variable remoteIndex | Out-Null
        $remoteIndex = [int]$remoteIndex - 1
        $remote = $RemoteList[$remoteIndex]

        Write-Host "`nThe remote '" -NoNewLine
        Write-Host "$remote" -ForegroundColor DarkYellow -NoNewLine
        Write-Host "' will be used to set up the Repository."
        Write-Host "You can enter the path to a subdirectory to set it up there (e.g. " -NoNewLine
        Write-Host "$remote" -ForegroundColor DarkYellow -NoNewLine
        Write-Host "path/to/folder" -ForegroundColor DarkCyan -NoNewLine
        Write-Host " - just enter the path)`n"

        Get-UserInput -Prompt "Please enter the path or leave blank to use root folder" -Default "" `
            | Tee-Object -Variable remoteFolder | Out-Null
        
        $remoteFolder = $remoteFolder.Trim() -replace '\\', '/' -replace '^\/*|\/*$'
        $remotePath = ($remote + $remoteFolder) -replace '^(.*\s.*)$', '"$1"'
        $testfile = (
            $remote + $remoteFolder + "/" + `
            (-join (1..16 | ForEach-Object {[char]((65..90) + (48..57) | Get-Random)})) + `
            ".tmp"
        ) -replace '^(.*\s.*)$', '"$1"' 

        
        Write-Host "`nChecking remote path '$remotePath'..." -NoNewline

        & $Paths.RclonePath mkdir $remotePath `
            --config "`"$($Paths.RcloneConfigPath)`"" `
            --retries 1 --low-level-retries 1 -q 2>&1 `
            | Tee-Object -Variable mkdirOutput | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to access the path specified: '$remotePath'"
        }

        & $Paths.RclonePath lsd $remotePath `
            --config "`"$($Paths.RcloneConfigPath)`"" `
            --retries 1 --low-level-retries 1 -q 2>&1 `
            | Tee-Object -Variable lsdOutput | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to modify the directory because of insufficient access rights or a connection issue"
        }

        & $Paths.RclonePath touch $testfile `
            --config "`"$($Paths.RcloneConfigPath)`"" `
            --retries 1 --low-level-retries 1 -q 2>&1 `
            | Tee-Object -Variable touchOutput | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to modify the directory because of insufficient access rights or a connection issue."
        }

        & $Paths.RclonePath deletefile $testfile `
            --config "`"$($Paths.RcloneConfigPath)`"" `
            --retries 1 --low-level-retries 1 -q 2>&1 `
            | Tee-Object -Variable deletefileOutput | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to modify the directory because of insufficient access rights or a connection issue."
        }

        Write-Host "`rRemote path: '$remotePath' has read and write permissions." -ForegroundColor DarkGreen
        $Paths["RepoPath"] = $remotePath

        return $Paths
    } catch {
        Write-Host
        throw $_.Exception.Message
    }
}