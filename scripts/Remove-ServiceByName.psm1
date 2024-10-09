function Remove-ServiceByName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if (-not $service) {
        throw "Service '$ServiceName' does not exist."
    }

    try {
        if ($service.Status -eq 'Running') {
            Write-Host "- Service '$ServiceName' is running. Stopping the service... " -NoNewLine
            Stop-Service -Name $ServiceName -Force -PassThru -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
            Write-Host "> Service '$ServiceName' has been stopped." -ForegroundColor DarkGreen
        }

        Write-Host "- Deleting service '$ServiceName'... " -NoNewLine
        sc.exe delete $ServiceName | Out-Null

        Start-Sleep -Seconds 2  # Wait a few seconds for the system to process the deletion
        $serviceCheck = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($serviceCheck) {
            Write-Host "> Failed." -ForegroundColor DarkGreen
            throw "Failed to delete the service '$ServiceName'."
        } else {
            Write-Host "> Service '$ServiceName' has been successfully deleted." -ForegroundColor DarkGreen
        }

    } catch {
        throw "An error occurred while trying to remove the service '$ServiceName': $_"
    }
}
