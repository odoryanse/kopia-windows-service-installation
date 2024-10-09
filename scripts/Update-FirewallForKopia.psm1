function Update-FirewallForKopia {
    param(
        [hashtable]$Paths,
        [int]$Port = 51515,
        [ValidateSet("TCP", "UDP")]
        [string]$Protocol = "TCP",
        [string]$RuleName = "AllowPortForKopia"
    )
    $KopiaExePath = "$($Paths.BasePath)\kopia.exe"

    if (-not (Test-Path -Path $KopiaExePath -PathType Leaf)) {
        throw "The executable file '$KopiaExePath' does not exist."
    }

    try {
        netsh advfirewall firewall show rule name=`"$RuleName`" dir=in | Out-Null
        if ($LASTEXITCODE -eq 0) {
            netsh advfirewall firewall delete rule name=`"$RuleName`" dir=in | Out-Null
        }

        netsh advfirewall firewall add rule name=`"$RuleName`" `
            dir=in action=allow program=`"$KopiaExePath`" enable=yes `
            localport=$Port protocol=$Protocol `
            | Tee-Object -Variable netshAddRuleError | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully added firewall rule for $KopiaExePath on port $Port." -ForegroundColor Green
        } else {
            throw "Failed to add firewall rule. $($netshAddRuleError[1])"
        }
    } catch {
        throw "Error executing netsh command: $_"
    }
}
