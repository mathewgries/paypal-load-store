using namespace System.Collections.Generic
using module ".\Logger.psm1"
using module ".\SMTP.psm1"

class ErrorLog {
    [int]$errorCount = 0
    [int]$environment = $null
    [Logger]$logger = $null
    [SMTP]$smtp = $null
    
    [String]$fromAddress = 'noreply@freedompay.com'
    [String]$toAddress = 'appsupport@freedompay.com'
    [String]$ccAddress = 'matt.gries@freedompay.com'
    [String]$subject = 'PayPal OnBoard Results'
    [String]$header = '<h1>PayPal OnBoard Process Results</h1>'
    [String]$listBlock = 'list-block'
    [String]$msg = $null

    ErrorLog([Logger]$logger, [SMTP]$smtp) {
        $this.logger = $logger
        $this.smtp = $smtp
        $this.init()
    }

    [void]init() {
        $this.smtp.setFromAddress($this.fromAddress)
        $this.smtp.setToAddress($this.toAddress)
        $this.smtp.setCCAddress($this.ccAddress)
        $this.smtp.setSubject($this.subject)
        $this.smtp.setHeader($this.header)
    }

    [SMTP]getSMTP() {
        return $this.smtp
    }

    [void]updateErrorCount() {
        $this.errorCount = $this.errorCount + 1
    }

    [void]invalidStart([int]$env) {
        $this.msg = 'Cannot Start Application'
        $this.smtp.updateBody("<div><div><h3><b>$($this.msg)</b></h3></div>")
        $this.logger.writeToLog($this.msg, 3)
    
        $this.msg = 'Invalid Environemnt:'
        $this.smtp.updateBody("<div class=$($this.listBlock)><ul><li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 3)
    
        $this.msg = 'Expected: 1 - 4'
        $this.smtp.updateBody("<li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 3)
        
        $this.msg = "Value Provided: $($env)"
        $this.smtp.updateBody("<li>$($this.msg)</li></ul></div></div>")
        $this.logger.writeToLog($this.msg, 3)
        $this.updateErrorCount()
    }

    [void]invalidDirectory([String]$directory) {
        $this.msg = 'Directory Not Found'
        $this.smtp.updateBody("<div><div><h3><b>$($this.msg)</b></h3></div>")
        $this.logger.writeToLog($this.msg, 3)

        $this.msg = "Directory: $($directory)"
        $this.smtp.updateBody("<div class=$($this.listBlock)><ul><li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 3)

        $this.msg = "Application Aborted"
        $this.smtp.updateBody("<li>$($this.msg)</li></ul></div></div>")
        $this.logger.writeToLog($this.msg, 3)
        $this.updateErrorCount()
    }

    [void]invalidFormInput([String]$filename, [List[PSCustomObject]]$errorList) {
        $this.msg = "Invalid Input Data: $($filename) - (File Skipped)"
        $this.smtp.updateBody("<div><div><h3><b>$($this.msg)</b></h3></div>")
        $this.logger.writeToLog($this.msg, 2)

        $this.smtp.updateBody("<div class=$($this.listBlock)><ul>")

        foreach ($err in $errorList) {
            $this.msg = $err.Name
            $this.smtp.updateBody("<li><div><h4><b>$($this.msg)</b></h4></div>")
            $this.logger.writeToLog($this.msg, 2)

            $this.smtp.updateBody("<div class=$($this.listBlock)><ul>")

            foreach ($props in $err.PsObject.Properties) {
                $this.msg = $props.Name + ": " + $props.Value
                $this.smtp.updateBody("<li>$($this.msg)</li>")
                $this.logger.writeToLog($this.msg, 2)
            }

            $this.smtp.updateBody("</ul></div></li>")
        }
        $this.smtp.updateBody("</ul></div><div>")
        $this.updateErrorCount()
    }

    [void]invalidFile([String]$filename, [String]$errorHeader) {
        $this.msg = $errorHeader
        $this.smtp.updateBody("<div><div><h3><b>$($this.msg)</b></h3></div>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "File name: $($filename)"
        $this.smtp.updateBody("<div class=$($this.listBlock)><ul><li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "Skipping File"
        $this.smtp.updateBody("<li>$($this.msg)</li></ul></div></div>")
        $this.logger.writeToLog($this.msg, 2)
        $this.updateErrorCount()
    }

    [void]invalidFile([String]$filename, [String]$errorHeader, [String]$body) {
        $this.msg = $errorHeader
        $this.smtp.updateBody("<div><div><h3><b>$($this.msg)</b></h3></div>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "File name: $($filename)"
        $this.smtp.updateBody("<div class=$($this.listBlock)><ul><li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = $body
        $this.smtp.updateBody("<li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 3)

        $this.msg = "Skipping File"
        $this.smtp.updateBody("<li>$($this.msg)</li></ul></div></div>")
        $this.logger.writeToLog($this.msg, 2)
        $this.updateErrorCount()
    }

    [void]databaseError([PSCustomObject]$err, [String]$sql) {
        $this.msg = "Database Error"
        $this.smtp.updateBody("<div><div><h3><b>$($this.msg)</b></h3></div>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "Message: $($err.Exception.Message)"
        $this.smtp.updateBody("<div class=$($this.listBlock)><ul><li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "See log files for more details"
        $this.smtp.updateBody("<li>$($this.msg)</li></ul>")
        
        $this.logger.writeToLog("ScriptStackTrace: " + $err.ScriptStackTrace, 3)
        $this.logger.writeToLog("SQL Script: " + $sql, 3)

        $this.updateErrorCount()
    }

    [void]dataLoadError([String]$errHeader, [String]$idName, [String]$id, [String]$filename) {
        $this.msg = "Failed to Load $($errHeader)"
        $this.smtp.updateBody("<div><div><h3><b>$($this.msg)</b></h3></div>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "$($idName): $($id)"
        $this.smtp.updateBody("<div class=$($this.listBlock)><ul><li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "File name: $($filename)"
        $this.smtp.updateBody("<li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "Skipping File"
        $this.smtp.updateBody("<li>$($this.msg)</li></ul></div></div>")
        $this.logger.writeToLog($this.msg, 2)
        $this.updateErrorCount()
    }

    [void]handleWebException([PSCustomObject]$response, [String]$title, [String]$storeId) {
        $this.msg = $title 
        $this.smtp.updateBody("<div><div><h3><b>$($this.msg)</b></h3></div>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "StoreID: $($storeId)"
        $this.smtp.updateBody("<div class=$($this.listBlock)><ul><li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "StatusCode: $($response.StatusCode)"
        $this.smtp.updateBody("<li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "StatusDescription: $($response.StatusDescription)"
        $this.smtp.updateBody("<li>$($this.msg)</li>")
        $this.logger.writeToLog($this.msg, 2)

        $this.msg = "Exception: $($response.Exception)"
        $this.smtp.updateBody("<li>$($this.msg)</li></ul></div></div>")
        $this.logger.writeToLog($this.msg, 2)
        $this.updateErrorCount()
    }
}