using namespace System.Collections.Generic

<#
    This is the Form object holding the data for each form
#>

class Form {
    [Hashtable]$formProps = $null
    [List[PSCustomObject]]$storeData = $null

    Form([String]$form) {
        $this.setFormProps($form)
    }

    [void]init() {
        $this.setStoreData()
    }

    # This is the powershell object containing the file meta data.
    # This is helpful in running actions against the form
    [void]setFormProps([String]$form) {
        $this.formProps = [ordered]@{}
        Get-ItemProperty -Path $form | ForEach-Object { 
            $_.PsObject.Properties | ForEach-Object { 
                $this.formProps[$_.Name] = $_.Value 
            }
        }
    }

    [Hashtable]getFormProps() {
        return $this.formProps
    }

    # This loads the data from each row to an object, and adds it to the enumerator list
    # -StartRow - This is the column header row. A new headler line gets added,
    # make this value the row where the columns are 
    # PayPalVenmo_Stores - The name of the sheet to import for the Excel workbook
    [void]setStoreData() {
        $path = $this.formProps.Item('FullName')
        $data = Import-Excel -Path $path -WorksheetName PayPalVenmo_Stores -StartRow 2 3>$null
        $this.storeData = $data
    }

    [PSCustomObject]getStoreData() {
        return $this.storeData
    }
}