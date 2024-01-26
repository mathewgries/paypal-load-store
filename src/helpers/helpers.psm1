using module "..\entities\form\Form.psm1"
Function Close-App {
    param(
        [Logger]$logger,
        [String]$message,    
        [int]$level,
        [SMTP]$smtp
    )

    [String]$timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
    
    if ($message) {
        $logger.writeToLog($message, $level)
    }

    if ($smtp) {
        if ($smtp.getBody() -ne '') {
            $smtp.setSubject($smtp.getSubject() + ' - ' + $timestamp)
            $smtp.sendEmail()
        }
    }
    
    $logger.writeToLog("Closing PayPal Load Store Application", $level)
    exit 1
}

Function Move-File {
    param(
        #Need to setup the file here
        [String]$outbound_dir,
        [Form]$form,
        [bool]$status,
        [Logger]$logger,
        [int]$level
    )

    [String]$formName = $form.getFormProps().Name
    [String]$fullPath = $form.getFormProps().FullName
    [String]$move_dir = $null
    [String]$movePath = $null
    
    if ($status) {
        $move_dir = $outbound_dir + '\success'
    }
    else {
        $move_dir = $outbound_dir + '\failed'
    }

    if (-NOT (Test-Path -Path $move_dir)) {
        New-Item -Path $move_dir -ItemType Directory | Out-Null
    }

    $movePath = $move_dir + '\' + $formName

    Copy-Item -Path $fullPath -Destination $movePath
    Remove-Item -Path $fullPath

    $logger.writeToLog("Moving: $($fullPath)", $level)
    $logger.writeToLog("New Location: $($movePath)", $level)
}