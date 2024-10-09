function Get-UserInput {
    [CmdletBinding()]
    param (
        [string]$Prompt = "Enter a value",
        [string]$Default = "Default"
    )
    
    $userInput = Read-Host -Prompt $Prompt
    
    if ($Default -and (-not $userInput -or $userInput -match '^\s*$' -or $userInput -eq $Default)) {
        $userInput = $Default
    }
    
    return $userInput
}

Export-ModuleMember -Function Get-UserInput