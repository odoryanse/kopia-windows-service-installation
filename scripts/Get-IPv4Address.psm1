function Get-IPv4Address {
    $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
                        Where-Object { $null -ne $_.IPAddress }

    $ipv4Addresses = @()
    $ipv4Regex = '^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$'

    foreach ($adapter in $networkAdapters) {
        foreach ($ip in $adapter.IPAddress) {
            if ($ip -match $ipv4Regex) {
                $ipv4Addresses += $ip
            }
        }
    }

    return ,$ipv4Addresses
}