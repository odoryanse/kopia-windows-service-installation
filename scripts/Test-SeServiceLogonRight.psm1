function Test-SeServiceLogonRight {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$User
    )

    try {
        $username = $User.Name
        $SID = $User.SID

        if ($UserName -eq "LocalSystem") {
            return $true
        }

        $tempPath = [System.IO.Path]::GetTempPath()
        $export = Join-Path -Path $tempPath -ChildPath "export.inf"
        if(Test-Path $export) { Remove-Temp -Path $export }

        if ($userName) {
            try {
                $ntAccount = New-Object System.Security.Principal.NTAccount($userName)
                $securityIdentifier = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
                $userSid = $securityIdentifier.Value
            } catch {
                throw "Failed to retrieve information about the user account"
            }
        }

        if ($userName -and $SID -and ($userSid -ne $SID)) {
            throw "The provided user does not have the same SID as the provided SID."
        }

        if ($SID -and (-not $userName)) {
            $user = Get-UserInfo -BySID -SID $SID
            $userName = $user.Name
            $userSid = $user.SID
        }

        secedit /export /cfg $export | Out-Null

        $isUsernameExists = Get-Content $export | Select-String -Pattern "SeServiceLogonRight = " | Select-String -Pattern "$userName"
        $isSidExists = Get-Content $export | Select-String -Pattern "SeServiceLogonRight = " | Select-String -Pattern "$userSid"

        if ($isUsernameExists -or $isSidExists) {
            return $true
        } else {
            return $false
        }
    } catch {    
        throw $_.Exception.Message
    } finally {
        Remove-Temp -Path $export
    }
}