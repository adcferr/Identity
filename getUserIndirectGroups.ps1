
#################################################################################
#DISCLAIMER: This is not an official PowerShell Script. We designed it specifically for the situation you have encountered right now.#Please do not modify or change any preset parameters. 
#Please note that we will not be able to support the script if it is changed or altered in any way or used in a different situation for other means.
#This code sample is provided "AS IT IS" without warranty of any kind, either expressed or implied, including but not limited to the implied warranties of merchantability and/or fitness for a particular purpose.
#This sample is not supported under any Microsoft standard support program or service.. 
#Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. #The entire risk arising out of the use or performance of the sample and documentation remains with you. 
#In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, 
#or other pecuniary loss) arising out of  the use of or inability to use the sample or documentation, even if Microsoft has been advised of the possibility of such damages.
#################################################################################

#====================================================================
# App in use must have Directory.Read.All and Member.Read.Hidden Graph API permissions
# user runing script minumum app admin
#====================================================================


#request path to save txt file

# $path_ = Read-Host "Full file path for txt list output (Filename included) "

#test vars
$path_ = read-host "Full file path: "

#log keep for CSV build
$Logs_1 = @()
$Logs_2 = @()
$logs_3 = @()

$allgroups =@{}

#check if $path is null or empty
$checkEmptyPath = [string]::IsNullOrEmpty($path_) 

if(!$checkEmptyPath) {
    #if $path is not null or empty

    Write-Host "Connecting..." -ForegroundColor Yellow

    #check if file has txt extension
    $testCsv = ($path_.substring($path_.length -4))

    #if filename does not have .txt extension add it to name
    if ($($testCsv.Tolower) -ne ".txt") {
        $path_ += ".txt"
    }

    
     $clientId = Read-host "AppId "  #id for app in my tenant
     $clientSecret = Read-host "AppSecret " #secret for app
     $tenantId = Read-host "TenantId " #tenant
     $userObjectId = Read-host "User ObjectId " #user to check groups

    $grantType = "client_credentials" #connection flow
    $oAuthUri = "https://login.microsoftonline.com/$tenantId/oauth2/token" 


    #*****************UserGroups******************************************
    $resourceAppIdUri = 'https://graph.microsoft.com'

    $authBody =@{
        grant_type = $grantType
        client_id = $clientId
        client_secret = $clientSecret
        resource = $resourceAppIdUri
    }

    #get access token
    $token = Invoke-RestMethod -Method POST -Uri $oAuthUri -Body $authBody -ContentType "application/x-www-form-urlencoded"

    #setting headers for the request
    $headers = @{
        "Content-Type" = "application/json"
        Accept = "application/json"
        Authorization = "Bearer $($token.access_token)"
    }

    ###############################################################
    # Direct Membership
    ###############################################################

    Write-Host "Collecting info..." -ForegroundColor Yellow

    #Get list of direct membership
    $GetUserMemberUrI = "https://graph.microsoft.com/v1.0/users/$userObjectId/memberOf"

    #Request list of direct Membership
    $response = Invoke-WebRequest -Method GET -Uri $GetUserMemberUrI -Headers $headers

    while($true){

        #get json reply to check if @odata.nexlink exists in current API call result 
         $workableJason = $response.Content | ConvertFrom-json
        
        #store all values in a workable json
        foreach($obj in $($workableJason.value)){

            #increment to already existing log
            $Logs_1 += $obj.displayName
        
        }
    
        if($workableJason.'@odata.nextlink') {
    
            $response = Invoke-WebRequest -Method GET -Uri $workableJason.'@odata.nextlink' -Headers $headers 
    
        } else {
    
            break
        }
    
    }


    ###############################################################
    # transitive Membership
    ###############################################################

    Write-Host "collecting transitives..." -ForegroundColor Yellow

    #get transitive membership
    $getUserMembership_transitiveURI = "https://graph.microsoft.com/beta/users/$userObjectId/transitiveMemberOf"

     #Request list of transitive Membership
     $response_ = Invoke-WebRequest -Method GET -Uri $getUserMembership_transitiveURI -Headers $headers


     while($true){

        #get json reply to check if @odata.nexlink exists in current API call result 
         $workableJason_ = $response_.Content | ConvertFrom-json
        
        foreach($obj_ in $($workableJason_.value)){

        #increment to already existing log
        $Logs_2 += $obj_.displayName
    
        }

        if($workableJason_.'@odata.nextlink') {
    
            $response_ = Invoke-WebRequest -Method GET -Uri $workableJason_.'@odata.nextlink' -Headers $headers 
    
        } else {
    
            break
        }
    
    }

  
    ###############################################################
    # tTable comparisson and generating final table
    ###############################################################

    Write-Host "Generating Table..." -ForegroundColor Yellow

    #cycle all values in log_2
    foreach($value_Log2 in $Logs_2){

        [bool]$exists = $false

        #search $value_log2 in $value_log1 ##.contains not working
        foreach($value_Log1 in $Logs_1) {

            #compare values and marks i
            if($value_Log1 -eq $value_Log2){ $exists = $true }

        }

        #if value from logs 2 does not exist in Log_1 them its an indirect group
        if(!($exists)){ 
            $logs_3+= $value_Log2
        }

    }
    
    #visual info
    Write-Host "Exporting txt..." -ForegroundColor Yellow

    #export log to csv
    $logs_3 | Out-File -FilePath $path_ 

    #visual info of script termination
    Write-Host "Txt file exported to $path_" -ForegroundColor Green

} else {
    #null or empty csv fila path
    write-output "File Path cannot be null or empty! Exiting..."
    
}


