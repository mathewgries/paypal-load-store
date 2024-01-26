using namespace System.Collections.Generic
using module "..\address\Address.psm1"

class Store {
    #region Declare properties
    [String]$storeID = $null
    [String]$sid = $null
    [String]$storeAlias = $null
    [String]$addressId = $null
    [Address]$address = $null
    
    [String]$venmoMID = $null
    [String]$paypalMID = $null
    [String]$longitude = $null
    [String]$latitude = $null
    [String]$locationId = $null
    [String]$internalName = $null

    #region Collections and Entities
    [Hashtable]$storeProcCfgs = [ordered]@{}
    [Hashtable]$configs = [ordered]@{}

    #region Constructors
    Store([PSCustomObject]$dataRow) {
        $this.setStoreID($dataRow)
        $this.setVenmoMID($dataRow)
        $this.setPaypalMID($dataRow)
        $this.setLongitude($dataRow)
        $this.setLatitude($dataRow)
    }

    #region Setters and Getters
    [void]setStoreID([PSCustomObject]$dataRow) {
        if ($dataRow.StoreID) {
            [String]$val = $dataRow.StoreID
            $this.storeID = $val.Trim()
        }
    }

    [String]getStoreID() {
        return $this.storeID
    }

    [void]setSid([String]$sid) {
        $this.sid = $sid
    }

    [String]getSid() {
        return $this.sid
    }

    [void]setStoreAlias([string]$val) {
        $this.storeAlias = $val
    }

    [string]getStoreAlias() {
        return $this.storeAlias
    }

    [void]setAddressId([String]$val) {
        $this.addressId = $val
    }

    [String]getAddressId() {
        return $this.addressId
    }

    [void]setAddress([PSCustomObject]$address) {
        $this.address = [Address]::new($address)
    }

    [Address]getAddress() {
        return $this.address
    }

    [void]setVenmoMID([PSCustomObject]$dataRow) {
        if ($dataRow.VenmoMerchantID) {
            [String]$val = $dataRow.VenmoMerchantID
            $this.venmoMID = $val.Trim()
        }
    }

    [String]getVenmoMID() {
        return $this.venmoMID
    }

    [void]setPaypalMID([PSCustomObject]$dataRow) {
        if ($dataRow.PayPalMerchantID) {
            [String]$val = $dataRow.PayPalMerchantID
            $this.paypalMID = $val.Trim()
            $this.configs.Add("PayPal.AccountId", $this.getPaypalMID())
        }
    }

    [String]getPaypalMID() {
        return $this.paypalMID
    }

    [void]setLongitude([PSCustomObject]$dataRow) {
        if ($dataRow.Longitude) {
            [String]$val = $dataRow.Longitude
            $this.longitude = $val.Trim()
        }
    }

    [void]setLongitude([String]$lon) {
        $this.longitude = $lon
    }

    [String]getLongitude() {
        return $this.longitude
    }

    [void]setLatitude([PSCustomObject]$dataRow) {
        if ($dataRow.Latitude) {
            [String]$val = $dataRow.Latitude
            $this.latitude = $val.Trim()
        }
    }

    [void]setLatitude([String]$lat) {
        $this.latitude = $lat
    }

    [String]getLatitude() {
        return $this.latitude
    }

    [void]setLocationId([String]$locationId) {
        $this.locationId = $locationId
    }

    [String]getLocationId() {
        return $this.locationId
    }

    [void]setInternalName([String]$internalName) {
        $this.internalName = $internalName
    }

    [String]getInternalName() {
        return $this.internalName
    }

    [void]addVenmoConfgis() {
        $this.configs.Add("Venmo.AccountId", $this.getVenmoMID())
        $this.configs.Add("Venmo.ExternalId", $this.getInternalName())
    }

    [void]setStoreProcCFG([Hashtable]$configs) {
        $this.storeProcCfgs = $configs
    }

    [Hashtable]getStoreProcCFG() {
        return $this.storeProcCfgs
    }

    [Hashtable]getConfigs() {
        return $this.configs
    }
}