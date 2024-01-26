using namespace System.Data
using namespace System.Management.Automation
using module "..\util\Logger.psm1"
using module "..\util\ErrorLog.psm1"
using module "..\util\SMTP.psm1"
Import-Module "$($PSScriptRoot)\..\helpers\helpers.psm1"

class Connection {
    [Environment]$environment
    [String]$readServer = $null
    [String]$writeServer = $null
    [String]$updateDatabase = "Caesium"
    [String]$queryDatabase = "Offloadium"
    [Logger]$logger = $null
    [ErrorLog]$errorLog = $null

    Connection([int]$env, [Logger]$logger, [ErrorLog]$errorLog) {
        $this.logger = $logger
        $this.errorLog = $errorLog
        $this.init($env)
    }

    Connection([int]$env) {
        $this.init($env)
    }

    [void]init([int]$env) {
        $this.setEnvironment($env)
        $this.setServer()
    }

    [void]setEnvironment([int]$env) {
        $this.environment = [Environment].GetEnumName($env)
    }

    [Environment]getEnvironment() {
        return $this.environment
    }

    [void]setServer() {
        Switch ($this.environment) {
            PROD { 
                $this.writeServer = "ENT-E01-DBG01"
                $this.readServer = "ENT-E01-DBG02,43291" 
            }
            UAT { 
                $this.writeServer = "UA1-ENT-DBG01"
                $this.readServer = "UA1-ENT-DBG02" 
            }
            QA {
                $this.writeServer = "QA1-FRWY-SQL01"  
                $this.readServer = "QA1-FRWY-SQL01" 
            }
            DEV { 
                $this.writeServer = "DEV1-FRWY-SQL01" 
                $this.readServer = "DEV1-FRWY-SQL01" 
            }
        }
    }

    [String]getWriteServer() {
        return $this.writeServer
    }

    [String]getReadServer() {
        return $this.readServer
    }

    [String]getQueryDB() {
        return $this.queryDatabase
    }

    [String]getUpdateDB() {
        return $this.queryDatabase
    }

    [DataSet]get([String]$sql) {
        [DataSet]$result = $null
        try {
            [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
            $instance = New-Object 'Microsoft.SqlServer.Management.Smo.Server' $this.readServer
            $result = $instance.databases[$this.queryDatabase].ExecuteWithResults($sql)
        }
        catch {
            $this.handleException($_, $sql)
        }
        return $result
    }

    [DataSet]saveCaesiumWithResult([String]$sql) {
        [DataSet]$result = $null
        try {
            [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
            $instance = New-Object 'Microsoft.SqlServer.Management.Smo.Server' $this.writeServer
            $result = $instance.databases[$this.updateDatabase].ExecuteWithResults($sql)
        }
        catch {
            $this.handleException($_, $sql)
        }
        return $result
    }

    [void]saveCaesium([String]$sql) {
        try {
            [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
            $instance = New-Object 'Microsoft.SqlServer.Management.Smo.Server' $this.writeServer
            $instance.databases[$this.updateDatabase].ExecuteWithResults($sql)
        }
        catch {
            $this.handleException($_, $sql)
        }
    }

    [void]handleException([ErrorRecord]$err, [String]$sql) {
        [system.exception]
        $this.errorLog.databaseError($err, $sql)
        Close-App -logger $this.logger -smtp $this.errorLog.getSMTP() -level 3
    }
}

Enum Environment{
    PROD = 1
    UAT = 2
    QA = 3
    DEV = 4
}