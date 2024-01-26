using namespace System.Data
using module "..\util\Logger.psm1"
using module ".\Connection.psm1"
using module "..\util\SMTP.psm1"
using module "..\Entities\address\Address.psm1"
using module "..\Entities\\store\Store.psm1"
Import-Module "$($PSScriptRoot)\..\helpers\helpers.psm1"

Function Get-StoreData {
    param(
        [Connection]$conn,
        [Store]$store
    )

    [bool]$status = $true
    [String]$storeID = $store.getStoreID()
    [DataSet]$results = $null
    [String]$sql = "SELECT sid, storeAlias, AddressId FROM Store WHERE storeId = '$($storeID)'"


    $results = $conn.get($sql)

    if ($null -ne $results.Tables[0].Rows -and $results.Tables[0].Rows.Count -gt 0) {
        $store.setSid($results.Tables[0].Rows[0][0])
        $store.setStoreAlias($results.Tables[0].Rows[0][1])
        $store.SetAddressId($results.Tables[0].Rows[0][2])
    }
    else {
        $status = $false
    }
    return $status
}

Function Get-StoreProcessorCFG {
    param(
        [Connection]$conn,
        [Store]$store
    )

    [bool]$status = $true
    [Hashtable]$configs = [ordered]@{}
    [DataSet]$results = $null
    [String]$sql = "SELECT name, value FROM StoreProcessorCfg WHERE sid = $($store.getSid())"

    $results = $conn.get($sql)
    if ($null -ne $results.Tables[0].Rows -and $results.Tables[0].Rows.Count -gt 0) {
        foreach ($row in $results.Tables[0]) {
            $configs[$row[0]] = $row[1]
        }
        $store.setStoreProcCFG($configs)
    }
    else {
        $status = $false
    }
    return $status
}

Function Get-Address {
    param(
        [Connection]$conn,
        [Store]$store
    )

    [bool]$status = $true
    [String]$addressId = $store.getAddressId()
    [DataSet]$results = $null
    [String]$sql = "SELECT TOP 1 street1, city, state, country, postalCode FROM Address WHERE id = '$($addressId)'"
    [PSCustomObject]$address = [PSCustomObject]@{
        addressId  = $addressId
        street     = $null
        city       = $null
        state      = $null
        country    = $null
        postalCode = $null
    }

    $results = $conn.get($sql)
    if ($null -ne $results.Tables[0].Rows -and $results.Tables[0].Rows.Count -gt 0) {
        $address.street = $results.Tables[0].Rows[0][0]
        $address.city = $results.Tables[0].Rows[0][1]
        $address.state = $results.Tables[0].Rows[0][2]
        $address.country = $results.Tables[0].Rows[0][3]
        $address.postalCode = $results.Tables[0].Rows[0][4]
        $store.setAddress($address)
    }
    else {
        $status = $false
    }
    return $status
}

Function Save-StoreProcessorCFG{
    param(
        [Connection]$conn,
        [Store]$store
    )

    [Hashtable]$configs = $store.getConfigs()

    [String]$procId = "89"
    [String]$exec = "`r`nexec StoreProcessorCfgReviseOne @username=@username, @sid=$($store.getSid()), @pid=$($procId),"
    [String]$sql = ""

    $sql += $declare
    $sql += Get-Ouput -configs $configs -exec $exec
    return $sql
    # $conn.saveCaesium($sql)
}

Function Get-Ouput{
    param(
        [Hashtable]$configs,
        [String]$exec,
        [String]$KKF
    )

    [String]$sql = ""
    foreach($config in $configs.GetEnumerator()){
        $val = $config.Value -replace '''', ''''''
        $sql += "$($exec) @name = '$($config.Key)',@value = '$($val)'"
        if($KKF){
            $sql += ",$($KKF)"
        }
    }
    return $sql
}