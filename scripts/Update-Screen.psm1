function New-DisplayControl {
    $displayControl = New-Object PSObject -Property @{
        Display      = @()
        Version      = $null
        Header       = "Kopia Windows Service Installation !ScriptVersion! - Odoryanse - VOZ Forum F13"
        Separator    = "---------------------------------------------------------------------"
        Refreshed    = $false
        TextColor    = [Console]::ForegroundColor
        QuietMode    = $true
    }

    $displayControl | Add-Member -MemberType ScriptMethod -Name "Init" -Value {
        param(
            [string]$version,
            [bool]$quiet,
            [string]$textColor
        )
        if ([string]$version -eq [string]$this.Version) { return }
        if ($textColor) { $this.TextColor = $textColor}
        $this.QuietMode = $quiet
        $this.Version = [string]$version
        $this.Header = @{
            Output = "Kopia Windows Service Installation $($this.Version) - Odoryanse - VOZ Forum F13"
            Color  = $this.TextColor
        }
        $this.Separator = @{
            Output = "$($this.Separator)`n"
            Color  = $this.TextColor
        }
        $this.Display = @($this.Header, $this.Separator)
        $Host.UI.RawUI.WindowTitle = $this.Header.Output
        $this.Refreshed = $false
    }

    $displayControl | Add-Member -MemberType ScriptMethod -Name "Write" -Value {
        param(
            [string]$LineOutput,
            [string]$TextColor,
            [bool]$Temp = $false,
            [bool]$NoNewLine,
            [bool]$Quiet = $false
        )
        if ($Temp -eq $false) {
            $this.Display += @{
                Output    = $LineOutput
                Color     = $TextColor
                NoNewLine = $NoNewLine
                Quiet     = $Quiet
            }
        }
        if ($this.QuietMode -and $Quiet) { return }
        if ($NoNewLine) {
            Write-Host "$LineOutput" -ForegroundColor $TextColor -NoNewLine
        } else {
            Write-Host "$LineOutput" -ForegroundColor $TextColor
        }
        
        $this.Refreshed = $false
        return ($this.Display.Length - 1)
    }

    $displayControl | Add-Member -MemberType ScriptMethod -Name "Replace" -Value {
        param (
            [int]$LineNumber,
            [string]$LineOutput,
            [string]$TextColor,
            [bool]$NoNewLine = $false,
            [bool]$Quiet = $false,
            [bool]$RemoveAfterLine = $false
        )
        if ($LineNumber -lt 0 -or $LineNumber -ge $this.Display.Length) {
            return
        }
        $this.Display[$LineNumber] = @{
            Output    = $LineOutput
            Color     = $TextColor
            NoNewLine = $NoNewLine
            Quiet     = $Quiet
        }
        if ($RemoveAfterLine) {
            $this.Display = $this.Display[0..$LineNumber]
        }
        $this.Refreshed = $false
        return $LineNumber
    }    

    $displayControl | Add-Member -MemberType ScriptMethod -Name "Refresh" -Value {
        if ($this.Refreshed) { return }
        Clear-Host
        foreach ($line in $this.Display) {
            if ($line -is [Hashtable]) {
                if ($this.QuietMode -and $line.Quiet) { return }
                if ($line.NoNewLine) {
                    Write-Host "$($line.Output)" -ForegroundColor $line.Color -NoNewLine
                } else {
                    Write-Host "$($line.Output)" -ForegroundColor $line.Color
                }
            } else {
                Write-Host $line
            }
        }
    }

    return $displayControl
}

$displayControl = New-DisplayControl

function Start-Screen {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Version,
        [switch]$QuietMode,
        [string]$Color = $displayControl.TextColor
    )

    $displayControl.Init($Version, $QuietMode, $Color)
    $displayControl.Refresh()
}

function Update-Screen {
    [CmdletBinding()]
    param(
        $Write,
        [string]$Color = $displayControl.TextColor,
        [int]$ReplaceLine,
        [switch]$RemoveAfterLine,
        [switch]$Separator,
        [switch]$Temp,
        [switch]$Refresh,
        [switch]$NoNewLine,
        [switch]$Quiet,
        [int]$Pause,
        [switch]$ReturnLine
    )
    if ($ReplaceLines) { $displayControl.Remove($ReplaceLines) }
    if ($Refresh) { $displayControl.Refresh() }
    if ($Pause -gt 0) {
        $pauseOutput = "`nContinuing in $pause seconds..."
        $displayControl.Write($pauseOutput, $Color, $true, $NoNewLine, $Quiet) | Out-Null
        Start-Sleep -Seconds $pause
    }
    
    if ($Write -or ($Write -eq "") -or $Separator) {
        $lines = @()
        $result = @()
        $currentReplaceLine = $ReplaceLine

        if ($Separator) { 
            $lines += $displayControl.Separator.Output
        }
        if ($Write -or ($Write -eq "")) {
            $lines += $Write
        }
        foreach ($output in $lines) {
            if ($ReplaceLine) {
                $result += $displayControl.Replace($currentReplaceLine, $output, $Color, $NoNewLine, $Quiet, $RemoveAfterLine)
                $currentReplaceLine++
            } else {
                $result += $displayControl.Write($output, $Color, $Temp, $NoNewLine, $Quiet) 
            }
        }
    }
    if ($ReturnLine) {
        return $result
    }
}

Export-ModuleMember -Function Start-Screen
Export-ModuleMember -Function Update-Screen