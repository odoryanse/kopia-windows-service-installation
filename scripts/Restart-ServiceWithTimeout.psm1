
function Wait-Milliseconds {
    param (
        [int]$Milliseconds
    )
    $end = (Get-Date).AddMilliseconds($Milliseconds)
    while ((Get-Date) -lt $end) {
        Start-Sleep -Seconds 0.1
    }
}
function Restart-ServiceWithTimeout {
    param (
        [string]$ServiceName,
        [int]$timeout = 30
    )

    try {
        $elapsed = 0
        $waitStepMs = 200
        $totalSteps = ($timeout * 1000) / $waitStepMs

        Stop-Service -Name $ServiceName -Force -PassThru -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        while ((Get-Service -Name $ServiceName).Status -ne 'Stopped' -and $elapsed -lt $totalSteps) {
            Wait-Milliseconds -Milliseconds $waitStepMs
            $elapsed++
        }

        Start-Service -Name $ServiceName -PassThru -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        while ((Get-Service -Name $ServiceName).Status -ne 'Running' -and $elapsed -lt $totalSteps) {
            Wait-Milliseconds -Milliseconds $waitStepMs
            $elapsed++
        }
        Write-Host "The service '$ServiceName' has started successfully."
    } catch {
        throw "Timeout reached but the service '$ServiceName' has not started."
    }
}
