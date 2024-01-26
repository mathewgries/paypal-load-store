using module '..\libs\RequestHandler.psm1'

<#
    These methods create the actual request body, in the format needed
    to make the call to the paypal API for the specific request

    The RequestHandler() function is listed in
    /src/util/RequestHandler.psm1
    That function is the actual HTTP invokation to the API, and handles how to format a
    successful and failure response
#>

#=====================================  GET BEARER TOKEN  =========================================
Function accessToken([PSCustomObject]$data) {
    $params = @{
        Uri     = $data.Uri
        Method  = 'POST'
        Headers = @{
            "Accept"        = "application/json"
            "Content-Type"  = "application/json"
            "Authorization" = "Basic $($data.User)"
        }
        Body    = @{
            "Content-Type" = "application/x-www-form-urlencoded"
            "grant_type"   = "client_credentials"
        }
    }
    return RequestHandler($params)
}

#=====================================  SAVE STORE TO PAYAPL  ==================================
Function saveStore([PSCustomObject]$data) {
    
    [PSCustomObject]$body = [PSCustomObject]@{
        name         = $data.StoreName
        internalName = $data.StoreName
        mobility     = "fixed"
        address      = [PSCustomObject]@{
            line1      = $data.Address.getStreet()
            city       = $data.Address.getCity()
            state      = $data.Address.getState()
            postalCode = $data.Address.getPostalCode()
            country    = $data.Address.getCountry()
        }
        latitude     = $data.Coordinates.Latitude
        longitude    = $data.Coordinates.Longitude
        tabType      = "none"
        availability = "open"
        gratuityType = "STANDARD"
    }

    $params = @{
        Uri     = $data.Uri
        Method  = 'POST'
        Headers = @{
            "Accept"                = "application/json"
            "Content-Type"          = "application/json"
            "Authorization"         = "Bearer $($data.Token)"
            "PayPal-Auth-Assertion" = $data.AuthAssertion
        }
        Body    = $body | ConvertTo-Json -Depth 3
    }
    return RequestHandler($params)
}