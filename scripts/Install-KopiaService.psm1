function Install-KopiaService {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Paths,
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        [string]$ServiceDisplayName = $null,
        [string]$ServiceDescription = $null,
        [switch]$Force
    )

    $ToolsDirectory = $Paths.ToolsPath
    $ConfigsDirectory = $Paths.ConfigPath

    $serviceExists = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($serviceExists) {
        if (-not $Force) {
            Write-Host "Service '$ServiceName' already exists. Use -Force to reinstall the service."
            return
        }

        Write-Host "Stopping and uninstalling the existing service '$ServiceName'..."
        Remove-ServiceByName -ServiceName $ServiceName
    }
    
    $winswExeName = "$ServiceName-winsw.exe"
    $winswSourcePath = Join-Path -Path $ToolsDirectory -ChildPath "WinSW-x64.exe"
    $winswTargetPath = Join-Path -Path $ConfigsDirectory -ChildPath $winswExeName
    $ymlConfigPath = Join-Path -Path $ConfigsDirectory -ChildPath "$ServiceName-winsw.yml"
    
    if (Test-Path $winswSourcePath) {
        Write-Host "Copying WinSW executable to $winswTargetPath..."
        Copy-Item -Path $winswSourcePath -Destination $winswTargetPath
    } else {
        Write-Host "WinSW executable not found in $ToolsDirectory"
        return
    }

    Write-Host "Creating service YML configuration at $ymlConfigPath..."

    Set-KopiaServiceConfig `
        -Paths $Paths `
        -Id $ServiceName `
        -WebUIUsername $usernameWeb `
        -Address @{
            IP   = "127.0.0.1"
            Port = 51515
        } `
        -Insecure $true
        
    Write-Host "Service configuration YML created successfully."

    Write-Host "Installing the service '$ServiceName'..."
    & "$winswTargetPath" install

    Write-Host "Starting the service '$ServiceName'..."
    & "$winswTargetPath" start

    Write-Host "Service '$ServiceName' installed and started successfully."
}    