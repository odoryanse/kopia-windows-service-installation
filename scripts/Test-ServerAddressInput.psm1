function Test-ServerAddressInput {
    param (
        [string]$ServerAddress
    )
    $serverAddress = $serverAddress.Trim()

    if ($serverAddress -match '^(.*?):(.*)$') {
        $ip = $matches[1]
        $port = $matches[2]
    } else {
        throw "The address '$serverAddress' you entered is not a valid IP:Port format"
    }

    $regex = '^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$'
    if (-not ($ip -match $regex)) {
        throw "The IP '$ip' you entered is not a valid IP format"
    }

    if (-not (($port -as [int]) -and ([int]$port -ge 1) -and ([int]$port -le 65535))) {
        throw "The port '$port' you entered is not a valid port"
    }

    return @{
        IP      = $ip
        Port    = [int]$port
    }
}
