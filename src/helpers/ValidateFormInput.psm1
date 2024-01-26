using namespace System.Collections.Generic
using module "..\entities\form\Form.psm1"
using module "..\entities\store\Store.psm1"
Function ValidateFormInput {
    param([Form]$form)

    [int]$index = 3
    [List[PSCustomObject]]$storeData = [List[PSCustomObject]]::new()
    [list[PSCustomObject]]$validationList = [List[PSCustomObject]]::new()

    # Build object for verifying values
    $index = 3
    foreach ($row in $form.getStoreData()) {
        $storeData.Add(
            [PSCustomObject]@{
                Row              = $index
                StoreID          = $row.StoreID
                VenmoMerchantID  = $row.VenmoMerchantID
                PayPalMerchantID = $row.PayPalMerchantID
            }
        )
        $index += 1
    }

    # Verify each row has a StoreID
    foreach ($item in $storeData) {
        if (-NOT $item.StoreID) {
            $validationList.Add(
                [PSCustomObject]@{
                    Name = 'Missing StoreID'
                    Row  = $item.Row
                }
            )
        }
    }

    # Verify each row has at least one MerchantID
    foreach ($item in $storeData) {
        if ((-NOT $item.VenmoMerchantID) -AND (-NOT $item.PayPalMerchantID)) {
            $validationList.Add(
                [PSCustomObject]@{
                    Name = 'Missing MerchantID'
                    Row  = $item.Row
                }
            )
        }
    }

    # Verify StoreID/MerchantID is not listed twice
    [List[PSCustomObject]]$compare = [List[PSCustomObject]]::new($storeData)
    foreach ($item in $storeData) {
        $compare.Remove($item) | Out-Null
        foreach ($store in $compare) {
            if ($store.StoreID -eq $item.StoreID) {
                if ($store.VenmoMerchantID -ne $item.VenmoMerchantID) {
                    $validationList.Add(
                        [PSCustomObject]@{
                            Name          = 'Duplicated StoreID'
                            InitialRow    = $item.Row
                            DuplicateRow  = $store.Row
                            DuplicatedMID = 'VenmoMID'
                        }
                    )
                }
                if ($store.PayPalMerchantID -ne $item.PayPalMerchantID) {
                    $validationList.Add(
                        [PSCustomObject]@{
                            Name          = 'Duplicated StoreID'
                            InitialRow    = $item.Row
                            DuplicateRow  = $store.Row
                            DuplicatedMID = 'PaypalMID'
                        }
                    )
                }
            }
        }
    }

    return $validationList
}