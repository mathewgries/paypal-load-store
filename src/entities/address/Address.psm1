<#
    Pretty straight forward. The Address for the store
#>

class Address
{
    #region Declare properties
    [String]$id = $null
    [String]$street = $null
    [String]$city = $null
    [String]$state = $null
    [String]$postalCode = $null
    [String]$country = $null
    
    #region Constructors
    Address([PSCustomObject]$address){
        $this.id = $address.addressId
        $this.street = $address.street
        $this.city = $address.city
        $this.state = $address.state
        $this.country = $address.country
        $this.postalCode = $address.postalCode
    }

    #region Setters and Getters
    [void]setAddressId([String]$id){
        $this.id = $id
    }

    [String]getAddressId(){
        return $this.id
    }

    [Void]setStreet([String]$val){
        $this.street = $val
    }

    [string]getStreet(){
        return $this.street
    }

    [Void]setCity([String]$val){
        $this.city = $val
    }

    [string]getCity(){
        return $this.city
    }

    [Void]setState([String]$val){
        $this.state = $val
    }

    [string]getState(){
        return $this.state
    }

    [Void]setPostalCode([String]$val){
        $this.postalCode = $val
    }

    [string]getPostalCode(){
        return $this.postalCode
    }

    [Void]setCountry([String]$val){
        $this.country = $val
    }

    [string]getCountry(){
        return $this.country
    }
}