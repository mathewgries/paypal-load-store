<#
    This stores the SQL statements and outputs to a file once the app completes
    The statemes are manually run against the database
#>

class SqlOutput {
    [String]$FILENAME = "OnBoardScripts"
    [String]$EXT = ".sql"
    [String]$declare = "declare @username sysname `r`nset @username = system_user`r`n"
    [String]$directory = $null
    [String]$file = $null

    [String]$output = ""

    SqlOutput([String]$user) {
        $this.setDirectory($user)
        $this.output += $this.declare
    }

    [void]addOutputData([String]$val) {
        $this.output += $val
    }

    [String]getOutputData() {
        return $this.output
    }

    [void]setFileData() {
        $this.writeToFile()
    }

    [void]setDirectory($user) {
        $this.directory = "c:\users\$($user)\desktop\paypal\OnBoardScripts"
        if (-NOT (Test-Path -Path $this.directory)) {
            New-Item -Path $this.directory -ItemType Directory | Out-Null
        }
    }

    [void]createOutputFile() {
        [String]$timestamp = Get-Date -Format 'yyyyMMddTHHmmssffff'
        $this.file = "$($this.directory)\$($this.FILENAME)_$($timestamp)$($this.EXT)"
 
        New-Item -Path $this.file -ItemType File | Out-Null
    }

    [void]writeToFile() {
        Set-Content -Path $this.file -Value $this.output
    }

    [String]getFile() {
        return $this.file
    }
}