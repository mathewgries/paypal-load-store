class Logger {
    # Define constants
    [string]$LOG_DIRECTORY_NAME = "\logs"
    [string]$FILENAME = '\paypal_loadstore_log_'
    [string]$EXT = '.txt'
     
    # Directory and file properties
    [String]$log_directory = $null
    [String]$log_file = $null
 
    # Define variables
    [LoggingLevel]$level
 
    #region constructors
    Logger() {}
 
    # constructor overloaded with argument
    Logger([string]$root) {
        $this.setLogDirectory($root)
        $this.setLogFile()
    }
 
    # region setters and getters
    [void]setLogDirectory([String]$root) {
        $this.log_directory = $root + $this.LOG_DIRECTORY_NAME
        if (-NOT (Test-Path -Path $this.log_directory)) {
            New-Item -Path $this.log_directory -ItemType Directory | Out-Null
        }
    }
 
    [void]setLogFile() {
        if ($this.getLogFileCount() -eq 0) {
            $this.createNewLogFile()
        }
        else {
            $this.log_file = (Get-ChildItem $this.log_directory | 
                Sort-Object LastWriteTime | 
                Select-Object -last 1
            ).FullName
        }
 
        if (($this.log_file.Length / 1KB) -gt 2000) {
            $this.createNewLogFile()
        }
    }
 
    [void]createNewLogFile() {
        [String]$timestamp = Get-Date -Format 'yyyyMMddTHHmmssffff'
        $this.log_file = $this.log_directory + $this.FILENAME + $timestamp + $this.EXT
 
        New-Item -Path $this.log_file -ItemType File | Out-Null
    }
 
    [int]getLogFileCount() {
        return (Get-ChildItem $this.log_directory -Force | Select-Object -First 1 | Measure-Object).Count
    }
 
    [void]setLoggingLevel([int]$log_level) {
        $this.level = $log_level
    }
 
    # region do work
    # Write to log - No extra formatting
    [void]writeToLog([string]$message, [int]$log_level) {
        $this.setLoggingLevel($log_level)
        [String]$log_date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss:ffff' 
        [String]$full_message = '[' + $log_date + '] ' + $this.level + ': ' + $message 
        Out-File -FilePath $this.log_file -InputObject $full_message -Append
    }
 
    # Write to log - additional formatting (new line, carriage return, etc)
    [void]writeToLog([string]$message, [int]$log_level, [string]$formatter) {
        $this.setLoggingLevel($log_level)
        [String]$log_date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss:ffff' 
        [String]$full_message = $formatter + '[' + $log_date + '] ' + $this.level + ': ' + $message 
        Out-File -FilePath $this.log_file -InputObject $full_message -Append
    }
}

Enum LoggingLevel {
    Information = 1
    Warning = 2
    Error = 3
}