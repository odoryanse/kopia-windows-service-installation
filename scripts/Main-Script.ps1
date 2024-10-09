$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$kopiaDir = Split-Path -Path $scriptDir -Parent
$serviceName = "Kopia"

$modulesToImport = @(
    "Remove-Temp.psm1",
    "Get-UserChoice.psm1",
    "Get-UserInput.psm1",
    "Update-Screen.psm1",
    "Test-KopiaDirectoryStructure.psm1",
    "Set-KopiaServiceConfig.psm1",
    "Remove-ServiceByName.psm1",
    "Install-KopiaService.psm1",
    "Get-WindowsUserWithCredential.psm1",
    "Test-AdminRights.psm1",
    "Test-SeServiceLogonRight.psm1",
    "Grant-SeServiceLogonRight.psm1",
    "Set-UserLogonService.psm1",
    "Get-IPv4Address.psm1",
    "Update-HostsFile.psm1",
    "Update-FirewallForKopia.psm1",
    "Update-TlsConf_AltNames.psm1", 
    "Test-KopiaSSLExists.psm1", 
    "Test-ServerDomainInput.psm1",
    "Test-ServerHostnameInput.psm1", 
    "Test-ServerAddressInput.psm1",
    "New-KopiaRootCA.psm1",
    "New-KopiaSSL.psm1",
    "Get-KopiaSSLFingerprint.psm1",
    "New-HtpasswdFile.psm1",
    "Test-VCRedistributableX64.psm1",
    "Get-RcloneExecPath.psm1",
    "New-RcloneRemote.psm1",
    "Get-RepositoryPath.psm1",
    "New-Repository.psm1",
    "Confirm-KopiaRepoProvider.psm1",
    "Restart-ServiceWithTimeout.psm1"
)

foreach ($moduleName in $modulesToImport) {
    $modulePath = Join-Path -Path $scriptDir -ChildPath "$moduleName"

    try {
        if (-not (Test-Path $modulePath)) {
            Write-Host "Error: Module file not found at $modulePath" -ForegroundColor Red
            return
        }
        Import-Module -Name $modulePath -ErrorAction Stop
        Write-Verbose "Module '$moduleName' has been successfully loaded."
    } catch {
        Write-Host "Error loading module: $_" -ForegroundColor Red
    }
}

try {
    Start-Screen -Version "v0.9.1" -QuietMode
    Test-KopiaDirectoryStructure -BasePath $kopiaDir | Tee-Object -Variable paths | Out-Null

    # 1.1 Install Service Using WinSW
    Update-Screen -Write "1.  Install Windows service for Kopia" -Color White  
    Update-Screen -Write @("  > Install Service Using WinSW...", "") -ReturnLine -Color DarkCyan `
        | Tee-Object -Variable installServiceLine | Out-Null
    try {
        Update-Screen -Separator
        Get-UserInput `
            -Prompt "Enter the Kopia service name, or leave it blank to use the default name (Kopia)" `
            -Default "Kopia" `
            | Tee-Object -Variable serviceName | Out-Null
        Update-Screen -Write "Kopia Windows Service name: $serviceName`n" -Refresh -ReturnLine `
            | Tee-Object -Variable serviceNameLine | Out-Null
        Get-Service -Name $serviceName -ErrorAction SilentlyContinue `
            | Tee-Object -Variable service | Out-Null
        if ($service) {
            Write-Host (
                "The service '$serviceName' exists.`n`n" +
                "1. Skip this step and use the existing service`n" +
                "2. Overwrite the existing service`n"
            )
            Get-UserChoice -Prompt "Select the number corresponding to your choice" -Options @("1", "2") `
                | Tee-Object -Variable serviceInstallSelection | Out-Null
        }
        if ($serviceInstallSelection -eq "2") {
            Update-Screen -Write "Do you want to force install with this name?" -Refresh
            Update-Screen -Write "Services with duplicate names will be removed (CAUTION, CANNOT BE UNDONE)`n" -Color Red
            while ($serviceNameConfirm -ne $serviceName) {
                Get-UserInput `
                    -Prompt "Enter the Kopia service name again to confirm (leave blank to cancel)" `
                    -Default "" `
                    | Tee-Object -Variable serviceNameConfirm | Out-Null
                if ($serviceNameConfirm -eq "") { 
                    throw "The installation of the service was canceled due to an inappropriate name"
                }
                Update-Screen -Refresh
            }
        }

        if (-not $service -or $serviceNameConfirm) {
            Update-Screen -Write "- Installing service... " `
                -ReplaceLine $($serviceNameLine[0] + 1) -RemoveAfterLine
            Update-Screen -Refresh
        }
        if ($serviceNameConfirm -eq $serviceName) {
            Install-KopiaService -Paths $paths -ServiceName $serviceName -Force
        } 
        if (-not $service -and -not $serviceNameConfirm) {
            Install-KopiaService -Paths $paths -ServiceName $serviceName
        }
        Update-Screen -Write "  - Install Service Using WinSW " -NoNewLine `
            -ReplaceLine $installServiceLine[0] -RemoveAfterLine
        Update-Screen -Write "> Completed (Service name: $serviceName)" -Color DarkGreen -Refresh
    } catch {
        Update-Screen -Write "  - Install Service Using WinSW " -NoNewLine  `
            -ReplaceLine $installServiceLine[0] -RemoveAfterLine
        Update-Screen -Write "> Failed" -Color Red -Refresh
        Update-Screen -Write "    Error: $($_.Exception.Message)" -Color Red
        throw "Encountered an error installing Windows Service for Kopia"
    }
    
    # 1.2 Set up login account for Windows Service
    Update-Screen -Write @("  > Set up login account for the service...", "") `
        -Color DarkCyan -ReturnLine `
        | Tee-Object -Variable setupLoginLine | Out-Null
    try {
        Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'" `
            | Tee-Object -Variable service | Out-Null
        $currentServiceUserName = $service.StartName.Replace(".\", "")
        Update-Screen -Separator
        Write-Host "Select a Windows account to use for running the Kopia service"
        Write-Host "The account being used to start the service: $currentServiceUserName`n" -ForegroundColor DarkYellow
        Write-Host "1. Use the Local System account " -NoNewLine
        Write-Host "(unsafe; should be avoided)" -ForegroundColor Red
        Write-Host "2. Use a different account on the local machine`n" 
        Get-UserChoice -Prompt "Select the number corresponding to your choice" -Options @("1", "2") `
            | Tee-Object -Variable useLocalSystem | Out-Null
        while (-not $isServiceConfigured) {
            try {
                if ($useLocalSystem -eq "1") {
                    $user = @{
                        Name = "LocalSystem"
                        FQUsername = "LocalSystem"
                    }
                }

                while ($useLocalSystem -eq "2" -and $trySelectAdmin -ne "Y") {
                    Update-Screen -Refresh                    
                    $noticeAdminRights = $null
                    $trySelectAdmin = "Y"

                    Write-Host "You have chosen to use a different account to log in to the Kopia Windows service"
                    $user = Get-WindowsUserWithCredential

                    if (-not (Test-AdminRights -User $user)) {
                        $noticeAdminRights = (
                            "NOTICE: The selected account does not have the admin rights "+
                            "to use the Volume Shadow Copy Service."
                        )
                        Write-Host "`n$noticeAdminRights" -ForegroundColor DarkYellow
                        Write-Host (
                            "If Kopia lacks access to the Volume Shadow Copy Service, " +
                            "it may fail the snapshot task when encountering files that are opened with an exclusive lock in Windows."
                        )
                        Get-UserChoice -Prompt "`nDo you want to continue? `nPress [Y]es to proceed or [N]o to choose another account" `
                            -Options @("Y", "N") | Tee-Object -Variable trySelectAdmin | Out-Null
                    }
                }

                Update-Screen -Refresh
                Write-Host "The '$($user.FQUsername)' account is being configured as the login account for the Kopia Windows service...`n"


                if (-not (Test-SeServiceLogonRight -User $user)) {
                    Grant-SeServiceLogonRight -User $user
                }

                Set-UserLogonService -User $user -ServiceName $serviceName
                $isServiceConfigured = $true
            } catch {
                Write-Host "`nError: $($_.Exception.Message)`n" -ForegroundColor Red

                Get-UserChoice -Prompt "Try again? [Y]es, [N]o (use LocalSystem)" `
                    -Options @("Y", "N") `
                    | Tee-Object -Variable trySelection | Out-Null
                $noticeAdminRights = $null
                $trySelectAdmin = $null
            } finally {
                if ($trySelection -eq "N") {
                    $errorMessage = "    NOTICE: Failed to set '$($user.FQUsername)' as the service login. " +
                                    "Using Local System instead."
                    $isServiceConfigured = $true
                    Set-UserLogonService -ServiceName $serviceName `
                        -User @{
                            Name = "LocalSystem"
                        }
                }
            }
        }
        Update-Screen -Write "  - Set up login account for the service " `
            -ReplaceLine $setupLoginLine[0] -RemoveAfterLine -NoNewLine
        Update-Screen -Write "> Completed (Log on as '$($user.FQUsername)')" -Color DarkGreen -Refresh
        Update-Screen -Write (
            "    + The SeServiceLogonRight privilege has been granted to the '$($user.FQUsername)' account."  
        )
        if ($errorMessage) {
            Update-Screen -Write $errorMessage -Color DarkYellow -NoNewLine
            Update-Screen -Write " (Dangerous)" -Color Red
        }
        if ($noticeAdminRights) {
            Update-Screen -Write "    $noticeAdminRights" -Color DarkYellow
        }
    } catch {
        Update-Screen -Write "  - Set up login account for the service " `
            -ReplaceLine $setupLoginLine[0] -RemoveAfterLine `
            -NoNewLine
        Update-Screen -Write "> Failed" -Color "Red" -Refresh
        throw $_.Exception.Message
    }

    # 2.  Set up Kopia Server
    Update-Screen -Write "`n2.  Set up Kopia Server" -Color White

    # 2.1 Network addresss
    Update-Screen -Write @("  > Setup network for the service...", "") -ReturnLine -Color DarkCyan `
        | Tee-Object -Variable setNetworkLine | Out-Null
    Update-Screen -Separator

    Get-IPv4Address | Tee-Object -Variable ipv4Addresses | Out-Null
    if ($ipv4Addresses.Count -gt 0) {
        Write-Host "Do you want to access this Kopia server from another computer?"
        Write-Host "If you choose [Yes], this script will change the firewall settings`n" -ForegroundColor DarkYellow
        Write-Host "1. Yes "
        Write-Host "2. No`n" 
        Get-UserChoice -Prompt "Select the number corresponding to your choice" -Options @("1", "2") `
            | Tee-Object -Variable openPort | Out-Null
        Update-Screen -Write "- Public Kopia Server : $($openPort -eq "1")"
    }

    if ($openPort -eq "1") {
        $IPAddress = $ipv4Addresses[0]
    } else {
        $IPAddress = "127.0.0.1"
    }

    do {
        try {
            Update-Screen -Refresh
            Get-UserInput `
                -Prompt "`nEnter the hostname you want to use for the WebUI (leave blank for default 'kopia.local')" `
                -Default "kopia.local" `
                | Tee-Object -Variable serverHostName | Out-Null
            Test-ServerHostnameInput -Hostname $serverHostName `
                | Tee-Object -Variable serverHostName | Out-Null
            Update-Screen -Write "- Hostname            : $serverHostName"
            $tryEnterHostname -eq "N"
        }
        catch {
            Write-Host "`nError: $($_.Exception.Message)`n" -ForegroundColor Red
            Get-UserChoice -Prompt "Try again? [Y]es, [N]o (skip, use 'kopia.local')" `
                -Options @("Y", "N") `
                | Tee-Object -Variable tryEnterDomain | Out-Null
            if ($tryEnterHostname -eq "N") { $serverHostName = "kopia.local" }
        }
    } while ($tryEnterHostname -eq "Y")
   
    do {
        try {
            Update-Screen -Refresh
            Get-UserInput `
                -Prompt "`nEnter the domain name you want to use for the WebUI (leave blank to skip)" `
                -Default "" `
                | Tee-Object -Variable serverDomainName | Out-Null
            Test-ServerDomainInput -Domain $serverDomainName `
                | Tee-Object -Variable serverDomainName | Out-Null
            if ($serverDomainName) {
                Update-Screen -Write "- Domain name         : $serverDomainName"
            }
            $tryEnterDomain -eq "N"
        }
        catch {
            Write-Host "`nError: $($_.Exception.Message)`n" -ForegroundColor Red
            Get-UserChoice -Prompt "Try again? [Y]es, [N]o (skip)" `
                -Options @("Y", "N") `
                | Tee-Object -Variable tryEnterDomain | Out-Null
            if ($tryEnterDomain -eq "N") { $serverDomainName = "" }
        }
    } while ($tryEnterDomain -eq "Y")
    
    do {
        try {
            Update-Screen -Refresh
            Get-UserInput `
                -Prompt "`nEnter the IP address and port you want to use (leave blank for the default '$($IPAddress):51515')" `
                -Default "$($IPAddress):51515" `
                | Tee-Object -Variable serverAddress | Out-Null
            Test-ServerAddressInput -ServerAddress $serverAddress `
                | Tee-Object -Variable serverAddress | Out-Null
            Update-Screen -Write "- Kopia Server Address: $($serverAddress.IP):$($serverAddress.Port)"
            $tryEnterAddress = "N"
        }
        catch {
            Write-Host "`nError: $($_.Exception.Message)`n" -ForegroundColor Red
            Get-UserChoice -Prompt "Try again? [Y]es, [N]o (skip, use '$($IPAddress):51515')" `
                -Options @("Y", "N") `
                | Tee-Object -Variable tryEnterAddress | Out-Null
            if ($tryEnterDomain -eq "N") { 
                $serverAddress = @{
                    IP      = $IPAddress
                    Port    = 51515
                } 
            }
            $tryEnterAddress = "Y"
        }
    } while ($tryEnterAddress -eq "Y")

    do {
        Update-Screen -Refresh
        try {
            Update-HostsFile -IPAddress $serverAddress.IP -Hostname $serverHostName
            Update-FirewallForKopia -Paths $paths -Port $serverAddress.Port `
                -RuleName "Kopia Service - Allow Port $($serverAddress.Port)"
            
            $dnsEntries = @{
                "DNS.1" = $serverAddress.IP
                "DNS.2" = $serverHostName
                "DNS.3" = "www.$serverHostName"
            }
            if ($serverDomainName) {
                $dnsEntries["DNS.4"] = $serverDomainName
                $dnsEntries["DNS.5"] = "www.$serverDomainName"
            }
            Update-TlsConf_AltNames -Paths $paths -NewDnsEntries $dnsEntries
            $trySetupNetwork = "N"
        }
        catch {
            Write-Host "`nError: $($_.Exception.Message)`n" -ForegroundColor Red
            Get-UserChoice -Prompt "Try again? [Y]es, [N]o (skip)" `
                -Options @("Y", "N") `
                | Tee-Object -Variable trySetupNetwork | Out-Null
            if ($trySetupNetwork -eq "N") {
                $setupNetworkError = $_.Exception.Message
            }
        }
    } while ($trySetupNetwork -eq "Y")

    Update-Screen -Write "  - Setup network for the service " -NoNewLine `
        -ReplaceLine $setNetworkLine[0] -RemoveAfterLine
    if ($setupNetworkError) {
        Update-Screen -Write "> Failed." -Color Red -Refresh        
        Update-Screen -Write "  - Error: $setupNetworkError." -Color Red -Refresh
    } else {
        Update-Screen -Write "> Completed (Server address: '$($serverAddress.IP):$($serverAddress.Port)')" -Color DarkGreen -Refresh
    }

    # 2.2 Create SSL certificate for Kopia
    Update-Screen -Write @("  > Create SSL certificate for Kopia...", "") -ReturnLine -Color DarkCyan `
        | Tee-Object -Variable installSSLLine | Out-Null
    Update-Screen -Write "Creating CA certificate for Kopia... " -Separator
    $kopiaSSLExists = Test-KopiaSSLExists -Paths $paths
    if ($kopiaSSLExists) {
        Write-Host "`nThere is an existing certificate at the path $($paths.TLSPath)" -ForegroundColor DarkYellow
        Get-UserChoice -Prompt "Skip creating a new certificate and use the existing one? [Y]es, [N]o (create new)" `
            -Options @("Y", "N") `
            | Tee-Object -Variable overwriteCerts | Out-Null
    }
    if ((-not $overwriteCerts) -or ($overwriteCerts -eq "N")) {
        New-KopiaRootCA -Paths $paths | Out-Null
        Update-Screen -Write "Create SSL Certificate... "
        New-KopiaSSL -Paths $paths | Out-Null
        Update-Screen -Write "Generate SHA256 Fingerprint... "
    }    
    Get-KopiaSSLFingerprint -Paths $paths | Tee-Object -Variable SHA256 | Out-Null
    Update-Screen -Pause 2

    Update-Screen -Write "  - Create SSL certificate for Kopia " -NoNewLine `
        -ReplaceLine $installSSLLine[0] -RemoveAfterLine
    Update-Screen -Write "> Completed" -Color DarkGreen -Refresh
    Update-Screen -Write "    + Certificate files: '$($paths.TLSPath)'"
    Update-Screen -Write "    + SHA256: $SHA256"

    # 2.3 Set password for Kopia WebUI login
    Update-Screen -Write @("  > Set password for Kopia WebUI login...", "") -ReturnLine -Color DarkCyan `
        | Tee-Object -Variable setPasswordLine | Out-Null
    Update-Screen -Separator

    do {
        try {
            Update-Screen -Refresh
            Get-UserInput -Prompt "Enter a username for WebUI (case-sensitive)(leave blank for default 'kopia')" `
                -Default "kopia" `
                | Tee-Object -Variable usernameWeb | Out-Null
            Write-Host
            New-HtpasswdFile -Username $usernameWeb -Paths $paths
            $tryHtpasswdFile = "N"
        } catch {
            Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
            if ($_.Exception.Message -like "*Undefined exit code*") {
                Test-VCRedistributableX64 | Tee-Object -Variable VCRedistributableX64Exists | Out-Null
                if ($VCRedistributableX64Exists) {
                    Write-Host (
                        "`nThe installed version of Microsoft Visual C++ Redistributable x64 may not be compatible.`n" + 
                        "Please download and install the latest version from: https://aka.ms/vs/17/release/vc_redist.x64.exe`n"
                    )
                } else {
                    Write-Host (
                        "`nPlease download and install the latest version from: https://aka.ms/vs/17/release/vc_redist.x64.exe`n"
                    )
                }
            }
            $choiceMessage = "Try again? Press [Y]es to continue, or [N]o to skip this step."
            $tryHtpasswdFile = Get-UserChoice -Prompt $choiceMessage -Options @("Y", "N")
            if ($tryHtpasswdFile -eq "N") {
                $HtpasswdFileError = "Error: $($_.Exception.Message)"
            }
        }
    } while ($tryHtpasswdFile -eq "Y")
    
    Update-Screen -Write "  - Set password for Kopia WebUI login " -NoNewLine `
        -ReplaceLine $setPasswordLine[0] -RemoveAfterLine
    if ($HtpasswdFileError) {
        Update-Screen -Write "> Failed. Use -insecure flag." -Color Red -Refresh
        Update-Screen -Write $HtpasswdFileError -Color Red
        $insecure = $true
    } else {
        Update-Screen -Write "> Completed (WebUI Username: '$usernameWeb')" -Color DarkGreen -Refresh
        $insecure = $false
    }
        
    Set-KopiaServiceConfig `
        -Paths $Paths `
        -Id $ServiceName `
        -WebUIUsername $usernameWeb `
        -Address $serverAddress `
        -Insecure $insecure

    # 3.  Set up Repository for Kopia
    Update-Screen -Write "`n3.  Set up Repository for Kopia" -Color White
    # 3.1 Config Rclone
    Update-Screen -Write @("  > Configure repository with RClone...", "") -ReturnLine -Color DarkCyan `
        | Tee-Object -Variable setupRepoLine | Out-Null
    Update-Screen -Separator
    Write-Host (
        "Would you like to set up Rclone for the storage provider to use with Kopia?`n`n" +
        "1. Yes`n" +
        "2. Configure it later using the Web UI or CLI`n"
    )
    Get-UserChoice -Prompt "Select the number corresponding to your choice" -Options @("1", "2") `
        | Tee-Object -Variable repositorySelection | Out-Null
    
    while ($repositorySelection -eq "1" -and $trySetupRemote -ne "N") {
        try {
            if ($tryGetCredential) {
                Update-Screen -Refresh
                Write-Host (
                    "The password for the Windows account '$($user.Name)' is incorrect. " +
                    "You need to re-enter the password to execute the command"
                )
                $user = Get-WindowsUserWithCredential -ByName -Name $user.Name
                $tryGetCredential = $false
            }
            Update-Screen -Refresh
            Get-RcloneExecPath -Paths $paths | Tee-Object -Variable paths | Out-Null
            Update-Screen -Refresh
            New-RcloneRemote -Paths $paths | Tee-Object -Variable remoteList | Out-Null
            Update-Screen -Refresh
            Get-RepositoryPath -RemoteList $remoteList -Paths $paths `
                | Tee-Object -Variable paths | Out-Null
            New-Repository -Paths $paths -User $user
            $trySetupRemote = "N"
        } catch {
            Write-Host "`nError: $($_.Exception.Message)`n" -ForegroundColor Red
            $wrongWindowsPw = "This command cannot be run due to the error: The user name or password is incorrect"
            if ($_.Exception.Message -like "*$wrongWindowsPw*") {
                $tryGetCredential = $true
            }
            Get-UserChoice -Prompt "Try again? [Y]es, [N]o (skip)" `
                -Options @("Y", "N") `
                | Tee-Object -Variable trySetupRemote | Out-Null
            if ($trySetupRemote -eq "N") {
                $setupRepoError = $_.Exception.Message
            }
        }
    }

    Update-Screen -Write "  - Configure repository with RClone " -NoNewLine `
        -ReplaceLine $setupRepoLine[0] -RemoveAfterLine
    if ($repositorySelection -eq "2") {
        Update-Screen -Write "> Skipped" -Color DarkYellow -Refresh
    }
    if ($repositorySelection -eq "1" -and -not $setupRepoError) {
        Update-Screen -Write "> Completed (Repository path: $($paths.RepoPath))" -Color DarkGreen -Refresh
    }
    if ($repositorySelection -eq "1" -and $setupRepoError) {
        Update-Screen -Write "> Failed" -Color Red -Refresh
        throw $setupRepoError
    }

    Update-Screen -Write @("  > Validating repository...", "") -ReturnLine -Color DarkCyan `
        | Tee-Object -Variable validateRepoLine | Out-Null
    Update-Screen -Separator -Refresh
    
    try {
        if ($repositorySelection -ne "2") { Confirm-KopiaRepoProvider -Paths $paths }
    } catch {
        $validateRepoError = $_.Exception.Message
    }

    Update-Screen -Write "  - Validate repository " -NoNewLine `
        -ReplaceLine $validateRepoLine[0] -RemoveAfterLine
    if ($repositorySelection -eq "2") {
        Update-Screen -Write "> Skipped" -Color DarkYellow -Refresh
    }
    if (-not $validateRepoError -and $repositorySelection -ne "2") {
        Update-Screen -Write "> Completed" -Color DarkGreen -Refresh
    }
    if ($validateRepoError -and $repositorySelection -ne "2") {
        Update-Screen -Write "> Failed" -Color Red -Refresh
        throw $setupRepoError
    }
} catch {
    $scriptError = "Error: $($_.Exception.Message).`n"
} finally {
    Update-Screen -Write ""
    Update-Screen -Separator
    if ($scriptError) {
        Update-Screen -Write $scriptError -Color Red
        Update-Screen -Write "The installation process has completed with errors"
    } else {
        Write-Host "Waiting for service '$serviceName' to start..." -NoNewline
        Write-Host "`r" -NoNewline
        Restart-ServiceWithTimeout -ServiceName $serviceName
        Update-Screen -Write "`nThe installation process has completed"
    }
    exit
}

