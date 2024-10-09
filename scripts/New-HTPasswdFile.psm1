function New-HTPasswdFile {
    param (
        [string]$Username,
        [hashtable]$Paths
    )

    try {
        if (-not (Test-Path "$($paths.ToolsPath)\htpasswd.exe")) {
            throw "htpasswd.exe not found at $($paths.ToolsPath)"
        }

        $htpasswdFilePath = Join-Path $paths.ConfigPath "htpasswd"
        $userExists = (Test-Path $htpasswdFilePath) -and (Get-Content $htpasswdFilePath) -match "^${Username}:"

        & "$($paths.ToolsPath)\htpasswd.exe" -c "`"$htpasswdFilePath`"" "`"$Username`""

        switch ($LASTEXITCODE) {
            0 {
                if ($userExists) {
                    Write-Host "User $Username has been successfully updated."
                } else {
                    Write-Host "User $Username has been successfully created."
                }
            }
            1 {
                throw "Encountered an issue accessing files."
            }
            2 {
                throw "There was a syntax problem with the command line."
            }
            3 {
                throw "The interactively entered password did not match."
            }
            4 {
                throw "Operation was interrupted."
            }
            5 {
                throw "A value is too long (username, filename, password, or final computed record)."
            }
            6 {
                throw "The username contains illegal characters."
            }
            7 {
                throw "The file is not a valid password file."
            }
            default {
                throw "Undefined exit code: $LASTEXITCODE."
            }
        }
    } catch {
        throw $_.Exception.Message
    }
}