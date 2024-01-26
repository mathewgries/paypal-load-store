using module ".\..\..\api\PayPalApi.psm1"
using module ".\..\store\Store.psm1"
using module ".\..\address\Address.psm1"

class MapQuest {
    $key = "nQ7zPLz2gAADi7i175nuAAzj5Ih3PfM5"
   
    MapQuest() {}
    
    [PSCustomObject]getCoordinates([Address]$address) {
        [PSCustomObject]$response = $null

        [String]$uri = 'http://www.mapquestapi.com/geocoding/v1/address?key=' + $this.key
        $uri += '&street=' + $address.getStreet()
        $uri += '&city=' + $address.getCity()
        $uri += '&state=' + $address.getState()
        $uri += '&postalCode=' + $address.getPostalCode()
    
        [PSCustomObject]$data = [PSCustomObject]@{
            Uri = $uri
        }

        $response = getCoordinates($data)
        return $response
    }
}