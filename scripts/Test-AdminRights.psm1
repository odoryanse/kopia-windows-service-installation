function Test-AdminRights {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$User
    )
    try {
        $Username = $User.Name

        # Get the Administrators group using .NET framework (compatible with PowerShell 2.0)
        $adminsGroup = [ADSI]"WinNT://./Administrators"
        $isAdmin = $false

        foreach ($member in $adminsGroup.psbase.Invoke("Members")) {
            $memberObj = $member.GetType().InvokeMember("Name", 'GetProperty', $null, $member, $null)

            if ($memberObj -eq $Username) {
                $isAdmin = $true
                break
            }
        }

        if ($isAdmin) {
            # Write-Host "$Username has administrator rights." -ForegroundColor Green
            return $true
        } else {
            # Write-Host "$Username does not have administrator rights." -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        throw "An error occurred while checking administrator rights: $_"
    }
}
