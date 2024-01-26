using module "..\entities\store\Store.psm1"
Function Get-Coordinates {
    param([Store]$store)

    [bool]$status = $true
    $key = "nQ7zPLz2gAADi7i175nuAAzj5Ih3PfM5"
    # $secret = "W7o3C3FfzDb0ArDg"

    $address = $store.getAddress()

    $uri = 'http://www.mapquestapi.com/geocoding/v1/address?key=' + $key
    $uri += '&street=' + $address.getStreet()
    $uri += '&city=' + $address.getCity()
    $uri += '&state=' + $address.getState()
    $uri += '&postalCode=' + $address.getPostalCode()

    $params = @{
        Uri         = $uri
        contentType = 'application/json'
    }

    $res = Invoke-RestMethod @params
    # Write-Host $res.results.locations[0].latLng.lng
    if ($res.info.statuscode -eq 0) {
        $store.setLatitude($res.results.locations[0].latLng.lat)
        $store.setLongitude($res.results.locations[0].latLng.lng)
    }
    else {
        $status = $false
    }
    return $status
}