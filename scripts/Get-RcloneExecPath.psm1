function Get-RcloneExecPath {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Paths
    )
    try {
        Get-Command rclone -ErrorAction SilentlyContinue `
            | Tee-Object -Variable rcloneInstalled | Out-Null
        Test-Path -Path "$($Paths.ToolsPath)\rclone.exe" `
            | Tee-Object -Variable rcloneBundledExists | Out-Null

        if (-not $rcloneInstalled -and -not $rcloneBundledExists) {
            Write-Host "Rclone not found at '$($Paths.ToolsPath)\rclone.exe'"
            Write-Host "There are no other versions installed on this machine."
            throw "The repository setup has been aborted because Rclone could not be configured"
        }

        if ($rcloneInstalled -and $rcloneBundledExists) {
            Write-Host "Rclone has been found installed on your computer.`n"
            Write-Host "Source  : $($rcloneInstalled.Source)"
            Write-Host "Version : $($rcloneInstalled.Version)`n"

            Write-Host "Would you like to use this version of Rclone?`n"
            Write-Host "1. Yes"
            Write-Host "2. No. Use the Rclone version stored in '$($Paths.ToolsPath)\rclone.exe'`n"
            Get-UserChoice -Prompt "Select the number corresponding to your choice" -Options @("1", "2") `
                | Tee-Object -Variable rcloneChoice | Out-Null
        }

        if ($rcloneInstalled -and -not $rcloneBundledExists) {
            Write-Host "Rclone is installed, using rclone at '$($rcloneInstalled.Source)'"
            $rcloneChoice = "1"
        }
        
        if (-not $rcloneInstalled -and $rcloneBundledExists) {
            Write-Host "Rclone is not installed, using rclone at '$($Paths.ToolsPath)\rclone.exe'"
            $rcloneChoice = "2"
        }

        switch ($rcloneChoice) {
            "1" { 
                $Paths["RclonePath"] = $rcloneInstalled.Source
                $Paths["RcloneConfigPath"] = (rclone config file) | Select-String ".conf"
            }
            "2" { 
                $Paths["RclonePath"] = "$($Paths.ToolsPath)\rclone.exe"
                $Paths["RcloneConfigPath"] = "$($Paths.ConfigPath)\rclone.conf"
            }
        }
        return $Paths
    } catch {
        throw $_.Exception.Message
    }
}