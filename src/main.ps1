using namespace System.Collections.Generic
using module ".\server\Connection.psm1"
using module ".\util\Logger.psm1"
using module ".\util\SMTP.psm1"
using module ".\util\ErrorLog.psm1"
using module ".\entities\form\FormList.psm1"
using module ".\entities\store\Store.psm1"
using module ".\entities\paypal\PayPal.psm1"
using module ".\entities\output\SqlOutput.psm1"
using module ".\entities\output\StoreInfo.psm1"
Import-Module "$($PSScriptRoot)\server\Database.psm1"
Import-Module "$($PSScriptRoot)\helpers\helpers.psm1"
Import-Module "$($PSScriptRoot)\helpers\Get-Coordinates.psm1"
Import-Module "$($PSScriptRoot)\helpers\ValidateFormInput.psm1"


<#
    Author: Mathew Gries
    Date: 11/2020

    Detailed instructions on how to run the app, and troupble shooting known errors can be found here
    https://confluence.freedompay.com/display/AS/PayPal+Location+Create+App

    Synopsis:
    This application will take in an Excel file, preformatted by Jen Shoemaker. It will retirieve store info from
    the database, and create a request to the paypal API to create a store under the merchants paypal MerchantId. 
    Two files we be created once completed.
    SqlOutput: This file will contain the SQL scripts that need to be run on the Caesium database to load the store's
        processor info for paypal
    StoreInfo: This will an Excel file containing two tabs
        Success - the data will be for all successful store creations
        Failed - Any store that failed to be created on the paypal side, with the HTTP error that was received
        This file is to be uploaded to the NetSuite case along with the SRF. This file contains the paypal LocationId,
        which is not stored in the database. This is the only existing record of that value, and the AM should have this
        for their records


    /src/entities - This folder contains the class files for the application objects.
        This includes the objects holding form input data, the store info data, and the 
        paypal information for making requests to the API
    
#>


#==================================================================================================#
#
#                        ______     ___   _      _  ______     ___     _
#                       |  ___ \   / _ \ \ \    // |  ___ \   / _ \   | | 
#                       | |__| |  / /_\ \ \ \  //  | |__| |  / /_\ \  | |
#                       |  ___/  |  __  |  \ \//   |  ___/  |  __  |  | |
#                       | |      | |  | |   | |    | |      | |  | |  | |
#                       | |      | |  | |   | |    | |      | |  | |  | |____
#                       |_|      |_|  |_|   |_|    |_|      |_|  |_|  |______|
#
#
#==================================================================================================#

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Set Environment
# This will prompt the user for input on which environment they are running the app in
# The app will close if they enter 5
# This can only be run in UAT and PROD
[int]$SET_ENVIRONMENT = $null
do {
    Write-Host "Choose the environment:"
    Write-Host "1. PROD"
    Write-Host "2. UAT"
    Write-Host "3. QA"
    Write-Host "4. DEV"
    Write-Host "5. EXIT"
    $SET_ENVIRONMENT = Read-Host "Enter"

    if ($SET_ENVIRONMENT -eq 5) {
        exit
    }

}while ($SET_ENVIRONMENT -lt 1 -AND $SET_ENVIRONMENT -gt 4)

# Status Counts
# These are used to output the results of how many stores were run through
# It will also give a count of how many failed and returned an error
# The failure will also be visible in the feed as the stores fail
# The output file will contain any failures, and the message for the failure
[int]$totalStoreCount = 0
[int]$totalVenmoCount = 0
[int]$venmoSuccessCount = 0
[int]$venmoFailureCount = 0

# Directory variables
# These are used to locate the files to be processed
# Also to move the files once completed
[String]$user = $env:UserName
[string]$root = (Get-Item $PSScriptRoot).Parent.FullName
[string]$inbound = "${root}\inbound"
[string]$outbound = "${root}\outbound"

# Application objects
# logger - tracks the apps progress to a txt file
# errorLog - This class contains the error message formatting for the Exceptions that are thrown
# smtp - The class to handle emailing the results
# conn - Connection to the database for retrieving store info
[Logger]$logger = $null
[ErrorLog]$errorLog = $null
[SMTP]$smtp = $null
[Connection]$conn = $null

# paypal - Handles the various methods for formatting and sending the requests to the paypal API
# sqlOutput - The output to run on the database to load the store info for paypal processing
# storeInfo - Creates Excel file and exports for the user. Contains success and failed info
#   This gets uploaded to the NetSuite case for the AM to keep in their records
#   The paypal locationId is located in this form. We do not put that value in the database
#   This is the only place it is tracked, so be sure this gets on the NetSuite case
[PayPal]$paypal = $null
[SqlOutput]$sqlOutput = [SqlOutput]::new($user)
[StoreInfo]$storeInfo = [StoreInfo]::new($user)

# Form and Store object lists
# formList - A list of all files located in the inbound folder to be processed
# stores - A list of all stores located in each file. This gets cleared out each time a new form is loaded and run
[FormList]$formList = $null
[List[Store]]$stores = $null

#================================= SET UP THE APPLICATION  =========================================

<#
    Starting here, and ending at :formloop, we are initializing up the application objects
    that we declared above. The logger is created first for tracking the app.
#>

#====================================== SET UP LOGGER  =============================================

# Create the logger for outputting to log files
$logger = [Logger]::new($root)
$logger.writeToLog("Starting Process", 1, "`r`n")
Write-Host "Starting Process..."

#======================================= SET UP SMTP  ==============================================


$logger.writeToLog("Loading SMTP module...", 1)
Write-Host "Loading SMTP module..."
$smtp = [SMTP]::new($SET_ENVIRONMENT)
$logger.writeToLog("Testing SMPT connection: $($smtp.getSMTPServer())", 1)
if ($smtp.testSMTPConnection()) {
    Write-Host "SMTP module loaded"
    $logger.writeToLog("SMTP Connection test successful", 1)
}
else {
    $logger.writeToLog("SMTP Connection test failed", 3)
    Close-App -logger $logger -level 3
}

#===================================== SET UP ERRORLOG  ============================================

$logger.writeToLog("Loading ErrorLog module...", 1)
Write-Host "Loading ErrorLog module..."
$errorLog = [ErrorLog]::new($logger, $smtp)
$logger.writeToLog("ErrorLog module loaded", 1)
Write-Host "ErrorLog module loaded"

#==================================== VALIDATE DIRECTORES  ===========================================

$logger.writeToLog("Verifying inbound directory...", 1)
Write-Host "Verifying inbound directory..."
if (Test-Path -Path $inbound) {
    $logger.writeToLog("Inbound directory verified", 1)
    $logger.writeToLog("Verifying outbound directory", 1)
    if (-NOT (Test-Path -Path $outbound)) {
        New-Item -Path $outbound -ItemType Directory | Out-Null
    }
    Write-Host "Inbound and outbound directories verified"
    $logger.writeToLog("Inbound and outbound directories verified", 1)
}
else {
    Write-Host "Could not locate inound directory..."
    Write-Host "Aborting application..."
    $errorLog.invalidDirectory($inbound)
    Close-App -logger $logger -level 3 -smtp $errorLog.getSMTP()
}


#======================================= SET UP THE ENVIRONMENT ====================================

# #SET_ENVIRONMENT (int)
# # PROD = 1
# # UAT  = 2
# # QA   = 3
# # DEV  = 4

# fail app start if environment is not set properly
$logger.writeToLog("Loading Connection module...", 1)
Write-Host "Loading Connection module..."
if (($SET_ENVIRONMENT -gt 0) -and ($SET_ENVIRONMENT -lt 5)) {
    $conn = [Connection]::new($SET_ENVIRONMENT, $logger, $errorLog)
    $logger.writeToLog("Connection module loaded", 1)
    Write-Host "Connection module loaded"
}
else {
    # Do not start if environment is incorrectly set
    Write-Host "ERROR: Failure loading Connection module..."
    Write-Host "Please view log files for more information..." 
    Write-Host "Aborting application..."
    $errorLog.invalidStart($SET_ENVIRONMENT)
    Close-App -logger $logger -level 3 -smtp $errorLog.getSMTP()
}

#====================================== SET UP PAYPAL ==============================================

$logger.writeToLog("Loading PayPal module...", 1)
Write-Host "Loading PayPal module..."
$paypal = [PayPal]::new($SET_ENVIRONMENT)
$response = $paypal.generateAccessToken()
if ($response.StatusCode -eq 200) {
    $logger.writeToLog("PayPal module loaded", 1)
    Write-Host "PayPal module loaded"
}
else {
    Write-Host "Failure getting PayPal access token..."
    Write-Host "Aborting application..."
    $errorLog.handleWebException($response, 'Failure getting PayPal access token')
    Close-App -logger $logger -level 3 -smtp $errorLog.getSMTP()
}

# #==================================== SET UP FORM LIST =============================================

$logger.writeToLog("Loading forms from inbound...", 1)
Write-Host "Loading forms from inbound..."
$formList = [FormList]::new($inbound)
if ($formList.getFormCount() -gt 0) {
    Write-Host "Form list loaded"
    Write-Host "Form Count: $($formList.getFormCount())"
    $logger.writeToLog("Form list loaded: $($formList.formListToString())", 1)
}
else {
    Write-Host "No forms were found to import..."
    Write-Host "Aborting application"
    Close-App -logger $logger -level 1 -smtp $errorLog.getSMTP()
}


#================================== START THE PROCESSES  ==========================================

<#
    Start loading the forms from the director. This will run through each form, one at a time in
    the :formloop. Generally there will only ever be one form in the inbound folder though
#>


:formLoop foreach ($form in $formList.getForms()) {
    
    #=============================== SET UP THE FILE DATA ==========================================

    # Verify file exists and Load the worksheet data 
    $logger.writeToLog("Importing form: $($form.getFormProps().Name)", 1)
    Write-Host "Importing form: $($form.getFormProps().Name)..."
    if (Test-Path ($form.getFormProps().FullName)) {
        $form.init()
        Write-Host "Form imported successfully"
        $logger.writeToLog("Form imported successfully", 1)
    }
    else {
        Write-Host "Something went wrong. Could not find form..."
        Write-Host "Skipping form..."
        $errorLog.invalidFile($form.getFormProps().Name, 'Form Not Found', 'Directory: ' + $form.getFormProps().DirectoryName)
        continue formLoop
    }

    # Validate the form data is correct before proceeding
    # /helpers/ValidateFormInput
    $logger.writeToLog("Validating form data", 1)
    Write-Host "Validating form data..."
    [list[PSCustomObject]]$inputValidation = ValidateFormInput -form $form
    if ($inputValidation.Count -gt 0) {
        Write-Host "ERROR: Invalid form data..."
        Write-Host "Skipping Form: View logs for more information"
        $errorLog.invalidFormInput($form.getFormProps().Name, $inputValidation)
        Move-File -outbound_dir $outbound -form $form -status $false -logger $logger -level 2
        continue formLoop
    }
    else {
        $logger.writeToLog("Form data validated", 1)
        Write-Host "Form data validated"
    }

    #==================================== LOAD STORE DATA =======================================

    $logger.writeToLog("Loading store data from offloadium...", 1)
    Write-Host "Loading store data from offloadium..."
    $stores = [List[Store]]::new()


    # Loop through each row in the excel sheet, and create a store object for each one
    # First step is get the Offloadium.Store record
    # Second step is get the Offloadium.Address record using the Store tables AddressId for the store
    # Third setp is to get the GEO data (Long/Lat) if it is not provided by the client
    #   This may not work in prod at this time. If this step causes failure, reach out to SA
    #   to help while list the API url or FQDN on the jumpbox
    foreach ($row in $form.getStoreData()) {
        $totalStoreCount += 1
        [Store]$store = [Store]::new($row)
        Write-Host "Loading StoreId: $($store.getStoreId())"
        $logger.writeToLog("Loading StoreId: $($store.getStoreId())", 1)

        # Load Store table data
        $logger.writeToLog("Loading Store table data...", 1)
        Write-Host "Loading Store table data..."
        if (-NOT (Get-StoreData -conn $conn -store $store)) {
            Write-Host "ERROR: Failure loading Store table data..."
            Write-Host "Skipping form..."
            $errorLog.dataLoadError("Store", "StoreId", $store.getStoreID(), $form.getFormProps().Name)
            Move-File -outbound_dir $outbound -form $form -status $false -logger $logger -level 2
            continue formLoop
        }
        else {
            $logger.writeToLog("Store table data loaded", 1)
            Write-Host "Store table data loaded"
        }

        # Load Address table data
        $logger.writeToLog("Loading address table data...", 1)
        Write-Host "Loading address table data..."
        if (-NOT (Get-Address -conn $conn -store $store)) {
            Write-Host "ERROR: Failure loading address table data..."
            Write-Host "Skipping form..."
            $errorLog.dataLoadError("Address", "StoreId", $store.getStoreID(), $form.getFormProps().Name)
            Move-File -outbound_dir $outbound -form $form -status $false -logger $logger -level 2
            continue formLoop
        }
        else {
            $logger.writeToLog("Address table data loaded", 1)
            Write-Host "Address table data loaded"
        }
        
        # Load StoreProcessorCFG table data
        # $logger.writeToLog("Loading StoreProcessorCFG table data...", 1)
        # Write-Host "Loading StoreProcessorCFG table data..."
        # if (-NOT (Get-StoreProcessorCFG -conn $conn -store $store)) {
        #     Write-Host "ERROR: Failure loading StoreProcessorCFG table data..."
        #     Write-Host "Skipping form..."
        #     $errorLog.dataLoadError("StoreProcessorCFG", "StoreId", $store.getStoreID(), $form.getFormProps().Name)
        #     Move-File -outbound_dir $outbound -form $form -status $false -logger $logger -level 2
        #     continue formLoop
        # }
        # else {
        #     $logger.writeToLog("StoreProcessorCFG table data loaded", 1)
        #     Write-Host "StoreProcessorCFG table data loaded"
        # }

        # Load Geo Coordinate data if not provided
        # If this fails, Paul Roller will have to assist in allowing this API connection on the jumpbox
        if ((-NOT $store.getLatitude()) -OR (-NOT $store.getLongitude())) {
            $logger.writeToLog("Coordinates not provided...", 1)
            Write-Host "Coordinates not provided..."
            $logger.writeToLog("Loading coordinate data...", 1)
            Write-Host "Loading coordinate data..."
            if (-NOT (Get-Coordinates -store $store)) {
                Write-Host "Failed to load coordinate data..."
                Write-Host "Skipping form..."
                $errorLog.dataLoadError("Get-Coordinates", "StoreId", $store.getStoreID(), $form.getFormProps().Name)
                Move-File -outbound_dir $outbound -form $form -status $false -logger $logger -level 2
                continue formLoop
            }
            $logger.writeToLog("Coordinate data loaded", 1)
            Write-Host "Coordinate data loaded"
        }
        # Add store to list
        $stores.Add($store)
        Write-Host "StoreID: $($store.getStoreID()) loaded"
        $logger.writeToLog("StoreID: $($store.getStoreID()) loaded", 1)
    }
    
    $logger.writeToLog("Store data loaded", 1)
    Write-Host "Store data loaded"

    #================================ CREATE PAYPAL LOCATION ====================================

    <#
        Once all the store data is loaded, we will make a request to paypal, one store at a time.
        At the time of creation, they did not provide a bulk request method, which is why we are 
        sending one at a time.

        Before stores can be created, we have to request an accessToken from paypal. This token can
        be reused for each request. We request the token above when initializing the paypal object0. 
        Then validate the token on each loop. If the token expired or is invalid, we request a new token
    #>

    $logger.writeToLog("Begin Location Creation for Venmo...", 1)
    Write-Host "Begin Location Creation for Venmo..."
    foreach ($store in $stores) {
        if ($store.getVenmoMID()) {
            # PayPal might rate limit us, so we pause execution in order to prevent this
            Start-Sleep -Seconds 3
            $totalVenmoCount += 1
            $logger.writeToLog("Creating Venmo location for StoreID: $($store.getStoreID())", 1)
            Write-Host "Creating Venmo location for StoreID: $($store.getStoreID())..."
            # Validate the PayPal Access Token
            if ($paypal.validateToken()) {
                Write-Host "Refreshing paypal access token..."
                $logger.writeLog("Refreshing paypal access token...", 1)
                
                $tokenResponse = $paypal.generateAccessToken()
                if ($tokenResponse.StatusCode -eq 200) {
                    Write-Host "Paypal access token refreshed"
                    $logger.writeLog("Paypal access token refreshed", 1)   
                }
                else {
                    $errorLog.handleWebException($tokenResponse, 'Failed to get Access Token')
                    Write-Host "Failure to update token: Closing Application"
                    Move-File -outbound_dir $outbound -form $form -status $false -logger $logger -level 3
                    break formLoop
                }
            }
            
            # Create location on paypal. 
            $createLocationResponse = $paypal.getLocationId($store)
            # Then validate the response
            if ($createLocationResponse.StatusCode -eq 201) {
                $venmoSuccessCount += 1
                $storeInfo.addSucess($form.getFormProps().Name, $store)
                Write-Host "Venmo location created for StoreID: $($store.getStoreID())"
                $logger.writeToLog("Venmo locatino created for StoreID: $($store.getStoreID())", 1)
            }
            else {
                $venmoFailureCount += 1
                $storeInfo.addFailed($form.getFormProps().Name, $store, $createLocationResponse)
                Write-Host "Failure to create Venmo location - StoreID: $($store.getStoreID())"
                $errorLog.handleWebException($createLocationResponse, "Failed to create Venmo location", $store.getStoreID())
            }
        }
    }

    # Set the formname for SQL output statement
    # The resulting file will be run against Caesium to load the store data to the database
    # If multiple files are fun through, each output will be on the same file. 
    # The results will be separated by new lines, and a comment at the top of the file name
    $sqlOutput.addOutputData("`r`n --$($form.getFormProps().Name)")
    Write-Host "Adding exec statements to output..."
    foreach ($store in $stores) {
        $sqlOutput.addOutputData((Save-StoreProcessorCFG -conn $conn -store $store))
    }
    Write-Host "Exec statements added to output"

    Write-Host "Import Complete: $($form.getFormProps().Name)"
    $logger.writeToLog("Import Complete: $($form.getFormProps().Name)", 1)
    Move-File -outbound_dir $outbound -form $form -status $true -logger $logger -level 1
}

Write-Host "Total Stores: $($totalStoreCount)"
Write-Host "Total Venmo Stores: $($totalVenmoCount)"
Write-Host "Venmo Success Count: $($venmoSuccessCount)"
Write-Host "Venmo Failure Count: $($venmoFailureCount)"

Write-Host "Generating output files..."
$storeInfo.createOutputFile()
$sqlOutput.createOutputFile()
$sqlOutput.setFileData()
Start-Process notepad++ $sqlOutput.getFile()

Close-App -logger $logger -message "Process Complete" -level 1 -smtp $errorLog.getSMTP()