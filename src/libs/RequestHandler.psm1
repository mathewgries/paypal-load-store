<#
    This is the method handling the request to the API
    It will receive the resposne, format it, and send the data
    back to the calling method
#>

Function RequestHandler([PSCustomObject]$request) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    [PSCustomObject]$response = $null

    $response = try {
        Invoke-WebRequest @request
    }
    catch [System.Net.WebException] {
        [PSCustomObject]@{ 
            Exception         = $_.Exception
            StatusDescription = $_.Exception.Response.StatusDescription
            StatusCode        = [int]$_.Exception.Response.StatusCode
        }
    } 
    return $response
}