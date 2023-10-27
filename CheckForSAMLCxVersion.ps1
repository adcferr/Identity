#################################################################################
#DISCLAIMER: This is not an official PowerShell Script. We designed it specifically for the situation you have encountered right now.#Please do not modify or change any preset parameters. 
#Please note that we will not be able to support the script if it is changed or altered in any way or used in a different situation for other means.
#This code sample is provided "AS IT IS" without warranty of any kind, either expressed or implied, including but not limited to the implied warranties of merchantability and/or fitness for a particular purpose.
#This sample is not supported under any Microsoft standard support program or service.. 
#Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. #The entire risk arising out of the use or performance of the sample and documentation remains with you. 
#In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, 
#or other pecuniary loss) arising out of  the use of or inability to use the sample or documentation, even if Microsoft has been advised of the possibility of such damages.
#################################################################################



############### Check for SAML APPs in tenant ###############

#Connect to modules
Connect-AzureAD
Connect-MgGraph -scopes Application.Readwrite.All

#create empy log (list)
$Logs = @()

#initialize Progress bar
$pbCounter = 0

#request path to save csv file
$path_ = Read-Host "Full file path for csv output (Filename included) "

#check if file has CSV extension
$testCsv = ($path_.substring($path_.length -4))

#if filename does not have .csv extension add it to name
if ($($testCsv.Tolower) -ne ".csv") {
    $path_ += ".csv"
}

#Visual indication of current proccess only
Write-Host "Collectiong info..."

#get all Apps
$allApps = Get-MgServicePrincipal -All:$true 

#cycle apps
foreach ($app in $allApps) {

    #check if Null or Empty PreferredSingleSignOnMode
    [bool]$existsNoSSO= [string]::IsNullOrEmpty($app.PreferredSingleSignOnMode)
    
    #if Null or Empty -eq $false, PreferredSingleSignOnMode is defined
    if (!$existsNoSSO) {

        $Log = New-Object PSObject -Property @{
            
            #Get AppId for Current App
            "AppId" = $app.AppId

            #Get ObjectId for current App
            "ObjectId" = $app.ID
            
            #get App Display Name
            "DisplayName" = $app.DisplayName
            
            #Get SignOnMode for App
            "PreferredSingleSignOnMode" = $app.PreferredSingleSignOnMode
        }

        #increment to already existing log
        $Logs += $Log

    } else {

            # ...Other Actions
            
    }

    #export log to csv
    $Logs | Export-CSV -Path $path_ -NoTypeInformation -Encoding UTF8

    #progress Bar
    $pbCounter++
    Write-Progress -Activity 'Processing Apps' -CurrentOperation $app.DisplayName -PercentComplete (($pbCounter / $allApps.count) * 100)

}
#visual info of termination
Write-Host "Finished!"
