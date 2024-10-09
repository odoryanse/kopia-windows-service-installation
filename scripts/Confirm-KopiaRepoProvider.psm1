function Confirm-KopiaRepoProvider {
    [CmdletBinding()]
    param (
        [hashtable]$Paths
    )
    $validateRepo = Start-Process -FilePath "$($Paths.BasePath)\kopia.exe" -ArgumentList `
        "repository validate-provider", `
        "--config-file `"$($Paths.ConfigPath)\repository.config`"" `
        -PassThru -NoNewWindow
    
    # Cache Handle for Exit code, do not delete
    $validateHandle = $validateRepo.Handle
    $validateRepo.WaitForExit()
    
    if ($validateRepo.ExitCode -eq 0) {
        return
    } else {
        throw "The repository provider is not compatible with Kopia. Please check the permissions and the network connection."
    }
}