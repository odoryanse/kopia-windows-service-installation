function Get-WindowsUserWithCredential {
    param (
        [switch]$BySID,
        [string]$SID,
        [switch]$ByName,
        [string]$Name
    )
    try {
        if ($BySID -and $SID) {
            $user = Get-WmiObject Win32_UserAccount `
                | Where-Object { $_.SID -eq $SID } `
                | Select-Object -Property Domain, SID, FullName, Name
        }

        if ($ByName -and $Name) {
            $user = Get-WmiObject Win32_UserAccount `
                | Where-Object { $_.Name -eq $Name } `
                | Select-Object -Property Domain, SID, FullName, Name
        }

        if (-not ($BySID -or $ByName)) {
            # Use Get-WmiObject to retrieve users who are local and not disabled
            $users = Get-WmiObject Win32_UserAccount `
                | Where-Object { $_.LocalAccount -eq $true -and $_.Disabled -eq $false } `
                | Select-Object -Property Domain, SID, FullName, Name

            if ($users -is [System.Management.Automation.PSCustomObject]) {
                $users = @($users)
            }
            
            if ($users.Count -gt 0) {
                Write-Host "List of users on the system:`n"

                $selectionOptions = @()
                $counter = 1
                
                foreach ($user in $users) {
                    Write-Host "${counter}. $($user.Name)"
                    $selectionOptions += $counter
                    $counter++
                }
                
                Write-Host
                $selection = [int](Get-UserChoice -Prompt "Select the number corresponding to the user" -Options $selectionOptions)
                $user = $users[$selection - 1]
            }
        }

        if ($user) {
            $userTable = @{}
            $user | Get-Member -MemberType NoteProperty | ForEach-Object {
                $userTable[$_.Name] = $user.$($_.Name)
            }
            Write-Host ("`nPlease provide the password for the '$($userTable.Domain)\$($userTable.Name)' account")
            Write-Host "Enter the password: " -NoNewLine
            $password = Read-Host -AsSecureString
            $username = $userTable.Name
            $credential = New-Object System.Management.Automation.PSCredential($username, $password)
            $userTable["FQUsername"] = "$($userTable.Domain)\$($userTable.Name)"
            $userTable["Password"] = $password
            $userTable["Credential"] = $credential
            
            return $userTable
        } else {
            throw "No users found on the system."
        }
    } catch {
        throw $_.Exception.Message
    }
}