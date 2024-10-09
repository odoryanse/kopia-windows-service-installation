function Set-UserLogonService {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$User,
        [Parameter(Mandatory=$true)]
        [string]$ServiceName
    )

    try {
        if ($null -eq $User.Domain) {
            $User.Domain = $env:COMPUTERNAME
        }

        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
        
        if ($null -eq $service) {
            throw "Service '$ServiceName' does not exist."
        }

        if ($user.Name -eq "LocalSystem" -and $service.StartName -eq "LocalSystem") {
            return
        }

        try {
            Write-Host "- Stopping service '$ServiceName' to apply settings... " -NoNewLine
            Stop-Service -Name "$ServiceName" -PassThru `
                -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
            $elapsed = 0
            while ((Get-Service -Name $ServiceName).Status -ne 'Stopped' -and $elapsed -lt 150) {
                Wait-Milliseconds -Milliseconds 200
                $elapsed++
            }
            Write-Host "> Stopped successfully"  -ForegroundColor DarkGreen
        } catch {
            Write-Host
            throw "Failed to stop the service. Error: $_"
        }

        Write-Host "- Changing the log-on account for the service... " -NoNewLine
        if ($user.Name -eq "LocalSystem") {
            $result = $service.Change(
                $null,
                $null,
                $null,
                $null,
                "Automatic",
                $null,
                "$($User.Domain)\$($User.Name)",
                $null,
                $null,
                $null,
                $null
            )
        } else {
            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($User.Password)
            $result = $service.Change(
                $null,
                $null,
                $null,
                $null,
                "Automatic",
                $null,
                "$($User.Domain)\$($User.Name)",
                [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr),
                $null,
                $null,
                $null
            )
        }
        
        if ($result.ReturnValue -eq 0) {
            Write-Host "> Applied"  -ForegroundColor DarkGreen
            Write-Host "- Restarting the service to verify the account and password... " -NoNewLine
            $startResult = $service.StartService()
            if ($startResult.ReturnValue -eq 0) {
                Write-Host "> Started successfully" -ForegroundColor DarkCyan
                Write-Host "`n- The service has been successfully configured."
            } else {
                Write-Host "> Failed"  -ForegroundColor Red
                throw (
                    "Service '$ServiceName' failed to start. " +
                    "The password might be incorrect or the account is invalid. " +
                    "Error code: $($startResult.ReturnValue)"
                )
            }
        } else {
            Write-Host "> Failed"  -ForegroundColor Red
            throw "An error occurred while changing the logon account. Error code: $($result.ReturnValue)"
        }
    } catch {
        throw $_.Exception.Message
    } finally {
        if ($ptr) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    }
}