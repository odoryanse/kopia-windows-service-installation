function Remove-Temp {
    [CmdletBinding()]
    param ([string]$Path)

    # Get the system Temp directory (using a PowerShell 2.0 compatible method)
    $tempPath = [System.IO.Path]::GetTempPath()

    # Convert to the full path of the directory to be deleted
    try {
        $fullPath = (Get-Item $Path -ErrorAction Stop).FullName
    }
    catch {
        Write-Verbose "Error: Cannot find path '$Path' because it does not exist"
        return
    }

    # Stop if the directory to be deleted is not in Temp
    if ($fullPath -notlike "$tempPath*") {
        Write-Verbose "Error: Only content within the Temp directory can be deleted. Command has been canceled."
        return
    }

    # Delete
    try {
        Remove-Item -Path $Path -Recurse -Force
        Write-Verbose "Deleted temp file: '$fullPath'"
    } catch {
        Write-Verbose "Error: Cannot delete '$fullPath'"
    }
}