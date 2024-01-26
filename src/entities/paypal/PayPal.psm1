using module ".\..\..\api\PayPalApi.psm1"
using module ".\..\store\Store.psm1"

<#
    The big kahuna right here. This is where we set up the paypal data for making requests
    There are two sets of creds listed, and will be used based on the environment selected by the user
    These creds are the FreedomPay clientId and secret key for making requests to paypal

    The UAT Payer ID is for testing against the store in UAT with that payer ID

#>

class PayPal {
    [String]$token = $null
    [nullable[datetime]]$tokenExpirationUTC = $null
    [Int]$env = $null
    [String]$url = $null
    [String]$clientId = $null
    [String]$secret = $null

    #UAT PayerID
    # [String]$uatMerchID = "768JBMZR8NZUY"

    # UAT Credentials
    [String]$testClientId = "AaGqVstQCxuxS_IR7awuMV4IpKgXLgVLkUyANWigrysa7R0E6rMx0-Wxk6b087nqPIq9zdMYGtMM7XdA"
    [String]$testSecret = "EKN259oPOY79lbA2lXrHF2FSdi_N_xLfqXL76n30qnsdzhJ7h5SCvPi-I1RwKa6lrqpTPn13JX6dbc4X"
    [String]$testUrl = "https://api.sandbox.paypal.com"

    # Prod Credentials
    [String]$liveClientId = "AQgpPqGQBUGqy9riBSzvTekU_rM1tR16wBcE2jnvy3Q3pVlBeIlcL12Ku687vufMYNnjJu7hqQYEbpQM"
    [String]$liveSecret = "ELG4Wa5waNh2sB2cZhnpF-bzt--f3wcHs4EUP7-HoCu10evRJYE8S3kJxT9GB8K-qjL0K7NbUahIvJkq"
    [String]$liveuUrl = 'https://api.paypal.com'
   
    PayPal([Int]$env) {
        $this.env = $env
        if($env -eq 1){
            $this.url = $this.liveuUrl
            $this.clientId = $this.liveClientId
            $this.secret = $this.liveSecret
        }elseif ($env -eq 2) {
            $this.url = $this.testUrl
            $this.clientId = $this.testClientId
            $this.secret = $this.testSecret
        }
    }

    # This will format the credentials in the necessary format for making the request
    [String]encoder($val) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($val)
        return [Convert]::ToBase64String($bytes)
    }

    # Calls the accessToken() method in /api/PayPalApi.psm1
    [PSCustomObject]generateAccessToken() {
        # Build the data for the request to the API
        [String]$uri = $this.url + '/v1/oauth2/token'
        [String]$user = $this.encoder("$($this.clientId):$($this.secret)")
        # Response from the API
        [PSCustomObject]$response = $null
        
        # Format the requestObject
        [PSCustomObject]$data = [PSCustomObject]@{
            Uri  = $uri
            User = $user
        }

        # Call the API with the request object
        $response = accessToken($data)
        if ($response.StatusCode -eq 200) {
            # Parse the response baody, store the token, and expiration time of token
            $content = $response.Content | ConvertFrom-Json
            $this.token = $content.access_token
            $this.tokenExpirationUTC = ((Get-Date).ToUniversalTime()).AddSeconds($content.expires_in)
        }
        return $response
    }

    # Validates if token eixsits or if is expired
    [bool]validateToken() {
        [bool]$invalid = $false
        if (-NOt $this.token) {
            $invalid = $true
        }
        elseif ($this.tokenExpirationUTC -lt (Get-Date).ToUniversalTime()) {
            $invalid = $true
        }
        return $invalid
    }

    # Makes the request to save the store on the PayPal API
    # Calls saveStore() in /api/PayPalApi.psm1
    [PSCustomObject]getLocationId([Store]$store) {
        # Response from the request
        [PSCustomObject]$response = $null
        
        # Data for the request body
        [String]$uri = $this.url + '/v1/retail/locations'
        [String]$storeName = $store.getStoreAlias()
        if($storeName -match "-"){
            $storeName = $storeName -replace "-",""
            $storeName = $storeName -replace "  "," "
        } 
        [PSCustomObject]$coordinates = [PSCustomObject]@{
            Longitude = $store.getLongitude()
            Latitude  = $store.getLatitude()
        }

        # Create the request body
        [PSCustomObject]$data = [PSCustomObject]@{
            Uri           = $uri
            Token         = $this.token
            StoreName     = $storeName
            Coordinates   = $coordinates
            Address       = $store.getAddress()
            AuthAssertion = $this.encoder("{""alg"":""none""}") + "." + $this.encoder("{""payer_id"":""$($store.getVenmoMID())"",""iss"":""$($this.clientId)""}") + "."
        }

        # Make the request
        $response = saveStore($data)
        if ($response.StatusCode -eq 201) {
            # Parse the response body
            $content = $response.Content | ConvertFrom-Json
            $store.setLocationId($content.id)
            $store.setInternalName($content.internalName)
            $store.addVenmoConfgis()
        }
        return $response
    }
}