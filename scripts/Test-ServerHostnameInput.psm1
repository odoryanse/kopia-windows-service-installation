function Test-ServerHostnameInput {
    param (
        [string]$hostname
    )
    $hostname = $hostname.Trim()

    if ($hostname.Length -gt 255) {
        throw "Hostname is too long. It must not exceed 255 characters."
    }

    if (-not ($hostname -match '^(?!-)(?!.*--)[A-Za-z0-9-]{1,63}(?<!-)(\.[A-Za-z0-9-]{1,63})*$')) {
        throw "Invalid hostname format. It must consist of alphanumeric characters and hyphens, and cannot start or end with a hyphen."
    }

    return $hostname
}
