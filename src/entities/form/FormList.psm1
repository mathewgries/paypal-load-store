using namespace System.Collections.Generic
using module ".\Form.psm1"

<#
    This class is for holding a list of Form objects
    This is the list enumerated through in the main.ps1 :formloop
#>

class FormList {
    #region Declare properties
    [String]$inbound_dir = $null
    [List[Form]]$form_list = $null
    [int]$form_count = 0

    # region Constructors
    FormList([String]$inbound) {
        $this.form_list = [List[Form]]::new()
        $this.inbound_dir = $inbound
        $this.setForms()
    }

    [void]setForms() {
        [string]$dir = $this.inbound_dir
        [String[]]$forms = Get-ChildItem -Path $dir | ForEach-Object { 
            (Get-ItemProperty -Path $dir'\'$_).FullName
        }

        foreach ($form in $forms) {
            [Form]$obf = [Form]::new($form)
            $this.form_list.Add($obf)
            $this.incrementFormCount()
        }
    }

    [List[object]]getForms() {
        return $this.form_list
    }

    [void]incrementFormCount() {
        $this.form_count = $this.form_count + 1
    }

    [int]getFormCount() {
        return $this.form_count
    }
    
    [string]formListToString() {
        $result = $null

        $index = 0
        foreach ($form in $this.form_list) 
        {
            $result += "`r`n" + ++$index + ": " + $form.getFormProps().Name
        }
        return $result
    }
}