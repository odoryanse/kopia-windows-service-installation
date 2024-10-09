function Wait-Milliseconds {
    param (
        [int]$Milliseconds
    )
    $end = (Get-Date).AddMilliseconds($Milliseconds)
    while ((Get-Date) -lt $end) {
        Start-Sleep -Seconds 0.1
    }
}

function Get-UserChoice {
    [CmdletBinding()]
    param (
        [string]$Prompt,
        [Parameter(Mandatory=$true)]
        [string[]]$Options
    )

    $optionString = $Options -join ', '
    $firstTry = $true
    Write-Host "$Prompt [$optionString]: " -NoNewLine
    while ($true) {
        $choice = [System.Console]::ReadKey($false).KeyChar

        if ($Options -contains $choice) {
            Write-Host
            return $choice.ToString()
        } else {
            if ($firstTry) {
                Write-Host "`nInvalid choice. " -NoNewLine -ForegroundColor Red
                Write-Host "Please choose one of: [$optionString]: " -NoNewLine
                $firstTry = $false
            } else {
                Wait-Milliseconds -Milliseconds 120
                Write-Host "`rInvalid choice. Please choose one of: [$optionString]:  " -NoNewLine
                Write-Host "`rInvalid choice. " -NoNewLine -ForegroundColor Red
                Write-Host "Please choose one of: [$optionString]: " -NoNewLine
            }
        }
    }
}

Export-ModuleMember -Function Get-UserChoice