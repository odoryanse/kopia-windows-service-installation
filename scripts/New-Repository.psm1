function Get-ChildProcessIds ($ParentProcessId) {
    $childProcessIds = @()

    $filter = "ParentProcessId = '$($ParentProcessId)'"
    $childProcesses = Get-WmiObject -Class Win32_Process -Filter $filter

    foreach ($process in $childProcesses) {
        $childProcessIds += $process.ProcessId
        $childProcessIds += Get-ChildProcessIds $process.ProcessId
    }

    return $childProcessIds
}
function New-Repository {
    [CmdletBinding()]
    param (
        [hashtable]$Paths,
        [hashtable]$User
    )
    try {
        $currentUser = whoami
        $runasUser = "$($User.Hostname)\$($User.Name)"
        if ($User -and $User.Name -ne "LocalSystem" -and $currentUser -ine $runasUser) {
            Write-Host (
                "`nNOTICE: The account you selected to log on to Kopia service does not match the account running this script.`n" +
                "A new window will open under the account '$currentUser' for you to set up the repository.`n" +
                "The repository setup window will close automatically after the task is completed, and this script will continue.`n"
            ) -ForegroundColor DarkYellow
        }
        $createRepoArgs = @(
            "repository create rclone",
            "--config-file `"$($Paths.ConfigPath)\repository.config`"",
            "--rclone-exe `"$($Paths.RclonePath)`"",
            "--rclone-args=`"--config=$($Paths.RcloneConfigPath)`"",
            "--remote-path $($Paths.RepoPath)",
            "--ecc-overhead-percent 5",
            "--no-check-for-updates"
        )
        if ($null -eq $User.Credential) {
            $createRepo = Start-Process -FilePath "$($Paths.BasePath)\kopia.exe" `
            -ArgumentList $createRepoArgs `
            -PassThru -NoNewWindow
        } else {
            $createRepo = Start-Process -FilePath "$($Paths.BasePath)\kopia.exe" `
            -ArgumentList $createRepoArgs `
            -Credential $User.Credential `
            -PassThru -NoNewWindow
        }
        
        # Cache Handle for Exit code, do not delete
        $createHandle = $createRepo.Handle

        $createRepoChildProcesses = Get-ChildProcessIds $createRepo.Id
        $createRepo.WaitForExit()

        foreach ($id in $createRepoChildProcesses) {
            try {
                taskkill /PID $id /F > $null 2>&1 | Out-Null
            } catch {
                Write-Host "Process ID: $id. Error: $_"
            }
        }

        if (!$createRepo.HasExited) {
            Stop-Process -Id $createRepo.Id
        }
        
        if ($createRepo.ExitCode -eq 0) { return }

        $connectRepoArgs = @(
            "repository connect rclone",
            "--config-file `"$($Paths.ConfigPath)\repository.config`"",
            "--rclone-exe `"$($Paths.RclonePath)`"",
            "--rclone-args=`"--config=$($Paths.RcloneConfigPath)`"",
            "--remote-path $($Paths.RepoPath)"
        )
        if ($null -eq $User.Credential) {
            $connectRepo = Start-Process -FilePath "$($Paths.BasePath)\kopia.exe" `
            -ArgumentList $connectRepoArgs `
            -PassThru -NoNewWindow
        } else {
            $connectRepo = Start-Process -FilePath "$($Paths.BasePath)\kopia.exe" `
            -ArgumentList $connectRepoArgs `
            -Credential $User.Credential `
            -PassThru -NoNewWindow
        }
        
        # Cache Handle for Exit code, do not delete
        $connectHandle = $connectRepo.Handle

        $connectRepoChildProcesses = Get-ChildProcessIds $connectRepo.Id
        $connectRepo.WaitForExit()
        
        foreach ($id in $connectRepoChildProcesses) {
            try {
                taskkill /PID $id /F > $null 2>&1 | Out-Null
            } catch {
                Write-Host "Process ID: $id. Error: $_"
            }
        }

        if ($connectRepo.ExitCode -eq 0) {
            return
        } else {
            throw "Failed to connect to the repository. Please check the remote path or password."
        }
    }
    catch {
        throw $_.Exception.Message
    }
    finally {
        if ($createHandle) { Remove-Variable -Name createHandle }
        if ($connectHandle) { Remove-Variable -Name connectHandle }
    }
}