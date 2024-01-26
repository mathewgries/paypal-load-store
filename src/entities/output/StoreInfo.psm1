using namespace System.Collections.Generic
using module ".\..\store\Store.psm1"

<#
    This outputs an Excel file containing success and fail data for each store
#>

class StoreInfo {
    [String]$FILENAME = "OnBoardStatus"
    [String]$EXT = ".xlsx"
    [String]$directory = $null
    [String]$baseName = $null
    [String]$file = $null
    [List[PSCustomObject]]$success = $null
    [List[PSCustomObject]]$failed = $null
    
    StoreInfo([String]$user) {
        $this.success = [List[PSCustomObject]]::new()
        $this.failed = [List[PSCustomObject]]::new()
        $this.setDirectory($user)
    }

    [void]setDirectory($user) {
        $this.directory = "c:\users\$($user)\desktop\paypal\LocationCreateResults"
        if (-NOT (Test-Path -Path $this.directory)) {
            New-Item -Path $this.directory -ItemType Directory | Out-Null
        }
    }

    [void]createOutputFile() {
        [String]$timestamp = Get-Date -Format 'yyyyMMddTHHmmssffff'
        $this.file = "$($this.directory)\$($this.FILENAME)_$($timestamp)$($this.EXT)"

        $this.success | Export-Excel -Path $this.file -WorksheetName "Success" -BoldTopRow -NoNumberConversion * -AutoSize
        $this.failed  | Export-Excel -Path $this.file -WorksheetName "Failed"  -BoldTopRow -NoNumberConversion * -AutoSize
    }

    [void]addSucess([String]$formname, [Store]$store) {
        [PSCustomObject]$data = [PSCustomObject]@{
            StoreId      = $store.getStoreID()
            StoreName    = $store.getStoreAlias()
            InternalName = $store.getInternalName()
            VenmoMerchID = $store.getVenmoMID()
            LocationId   = $store.getLocationId()
            FormName     = $formname
        }
        $this.success.Add($data)
    }

    [void]addFailed([String]$formname, [Store]$store, [PSCustomObject]$response) {
        [PSCustomObject]$data = [PSCustomObject]@{
            StoreId           = $store.getStoreID()
            StoreName         = $store.getStoreAlias()
            VenmoMerchID      = $store.getVenmoMID()
            FormName          = $formname
            Comments          = ""
            StatusCode        = $response.StatusCode
            StatusDescription = $response.StatusDescription
            Exception         = $response.Exception 
        }
        $this.failed.Add($data)
    }
}