function Grant-SeServiceLogonRight {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$User
    )
    try {
        $userName = $User.Name
        $userNameWithHost = $User.FQUsername
        
        $tempPath = [System.IO.Path]::GetTempPath()
        $import = Join-Path -Path $tempPath -ChildPath "import.inf"
        if(Test-Path $import) { Remove-Temp -Path $import }
        $export = Join-Path -Path $tempPath -ChildPath "export.inf"
        if(Test-Path $export) { Remove-Temp -Path $export }
        $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
        if(Test-Path $secedt) { Remove-Temp -Path $secedt }
        $tmpLog = Join-Path -Path $tempPath -ChildPath "secedt.log"
        if(Test-Path $tmpLog) { Remove-Temp -Path $tmpLog }

        Write-Host "Granting SeServiceLogonRight to user account: '$userNameWithHost'..."

        secedit /export /cfg $export | Out-Null

        $ntAccount = New-Object System.Security.Principal.NTAccount($userName)
        $securityIdentifier = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
        $userSid = $securityIdentifier.Value
        
        if ((Get-Content -Path $export) -match "SeServiceLogonRight = .*") {
            $sids = (Select-String $export -Pattern "SeServiceLogonRight = ").Line
            foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "$sids,*$userSid")){
                Add-Content $import $line
            }
        } else {
            foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "SeServiceLogonRight = *$userSid")){
                Add-Content $import $line
            }
        }

        Write-Host "- Validating configuration...  " -NoNewLine
        $validationResult = secedit /validate $import
        if ($validationResult | Select-String '.*invalid.*') { 
            Write-Host "> Failed" -ForegroundColor Red
            throw $validationResult 
        }
        Write-Host "> Completed successfully" -ForegroundColor DarkCyan

        Write-Host  "- Importing new policy on temp database... " -NoNewLine
        $result = secedit /import /db $secedt /cfg $import 2>&1
        if ($LASTEXITCODE -ne 0) { 
            Write-Host "> Failed" -ForegroundColor Red
            throw "Error occurred during secedit import: $result" 
        }
        Write-Host "> Completed successfully" -ForegroundColor DarkCyan

        Write-Host "- Applying new policy to machine... " -NoNewLine
        $result = secedit /configure /db $secedt /log "$tmpLog" 2>&1
        if ($LASTEXITCODE -ne 0) { 
            Write-Host "> Failed" -ForegroundColor Red
            throw "Error occurred during secedit configuration: $result" 
        }
        $result = gpupdate /force 2>&1
        if ($LASTEXITCODE -ne 0) { 
            Write-Host "> Failed" -ForegroundColor Red
            throw "Error occurred during secedit configuration: $result" 
        }
        Write-Host "> Completed successfully" -ForegroundColor DarkCyan
        
        Write-Host "`nThe SeServiceLogonRight privilege has been granted to the '$userNameWithHost' account."
        Remove-Temp -Path $tmpLog
    } catch {    
        throw "Failed to grant SeServiceLogonRight to user account: '$userNameWithHost'. $($_.Exception.Message)"
    } finally {
        Remove-Temp -Path $import
        Remove-Temp -Path $export
        Remove-Temp -Path $secedt
    }
}