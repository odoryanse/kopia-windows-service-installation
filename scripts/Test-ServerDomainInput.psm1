function Test-ServerDomainInput {
    param (
        [string]$domain
    )
    $domain = $domain.Trim()

    if (-not $domain) {
        return ""
    }

    if ($domain -match '^(http://|https://)?(www\.)?([a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+)$') {
        $domain = $domain -replace '^(http://|https://)', ''
        $domain = $domain -replace '^www\.', ''
        return $domain
    } else {
        throw "Invalid domain: $domain"
    }
}
