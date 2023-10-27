#################################################################################
#DISCLAIMER: This is not an official PowerShell Script. We designed it specifically for the situation you have encountered right now.#Please do not modify or change any preset parameters. 
#Please note that we will not be able to support the script if it is changed or altered in any way or used in a different situation for other means.
#This code sample is provided "AS IT IS" without warranty of any kind, either expressed or implied, including but not limited to the implied warranties of merchantability and/or fitness for a particular purpose.
#This sample is not supported under any Microsoft standard support program or service.. 
#Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. #The entire risk arising out of the use or performance of the sample and documentation remains with you. 
#In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, 
#or other pecuniary loss) arising out of  the use of or inability to use the sample or documentation, even if Microsoft has been advised of the possibility of such damages.
#################################################################################



#Script to check all apps all users and groups are assigned to

#Connect Module
Connect-MgGraph -scopes AppRoleAssignment.ReadWrite.All,Application.ReadWrite.All,Directory.ReadWrite.All

#create empy log (list)
$Logs = @()

#initialize Progress bars
$pbCounter = 0
$pbCounter_ = 0

#request path to save csv file
$path_ = Read-Host "Full file path for csv output (Filename included) "

#check if $path is null or empty
$checkEmptyPath = [string]::IsNullOrEmpty($path_) 

if(!$checkEmptyPath) {
    #if $path is not null or empty

    #check if file has CSV extension
    $testCsv = ($path_.substring($path_.length -4))

    #if filename does not have .csv extension add it to name
    if ($($testCsv.Tolower) -ne ".csv") {
        $path_ += ".csv"
    }

    #get all Users
    $users = Get-MgUser -All:$true

    #get all groups
    $groups = Get-MgGroup -All:$true

    #Cycle trought users
    foreach ($user in $users){
        $getAppInfo = Get-MgUserAppRoleAssignment -UserId $user.Id    

        #log info
        $Log = New-Object System.Object

        $Log | Add-Member -MemberType NoteProperty -Name "ObjecType" -Value "User"

        $Log | Add-Member -MemberType NoteProperty -Name "Name" -Value $user.DisplayName
        
        #create empty array for apps list
        $appsList = @()

        #cycle trought all apps assigned to user
        foreach($app in $getAppInfo.ResourceDisplayName) {
                $appsList += $getAppInfo.ResourceDisplayName
            }
    
        #apps will show same number of times as roles of app user as assigned. Filter duplicate App Names    
        $appsList = $appsList | sort -Unique

        #convert array to single line string
        $arrayToString = $appsList -join " ; "

        #log apps
        $Log | Add-Member -MemberType NoteProperty -Name "Apps" -Value $arrayToString

        #increment existing log
        $Logs += $Log

        #progress Bar
        $pbCounter++
        Write-Progress -Activity 'Processing Users' -CurrentOperation $user.DisplayName -PercentComplete (($pbCounter / $users.count) * 100)

    }

    #Cycle trought Groups
    foreach ($group in $groups){
        $getAppInfo_ = Get-MgGroupAppRoleAssignment -GroupId $group.Id    

        #log info
        $Log = New-Object System.Object
        
        $Log | Add-Member -MemberType NoteProperty -Name "ObjecType" -Value "Group"

        $Log | Add-Member -MemberType NoteProperty -Name "Name" -Value $group.DisplayName
        
        #create empty array for apps list
        $appsList_ = @()

        #cycle trought all apps assigned to user
        foreach($app_ in $getAppInfo_.ResourceDisplayName) {
                $appsList_ += $getAppInfo_.ResourceDisplayName
            }
    
        #apps will show same number of times as roles of app group as assigned. Filter duplicate App Names 
        $appsList_ = $appsList_ | sort -Unique

        #convert array to single line string
        $arrayToString_ = $appsList_ -join " ; "

        #log apps
        $Log | Add-Member -MemberType NoteProperty -Name "Apps" -Value $arrayToString_

        #increment existing log
        $Logs += $Log

        #progress Bar
        $pbCounter_++
        Write-Progress -Activity 'Processing Groups' -CurrentOperation $group.DisplayName -PercentComplete (($pbCounter_ / $groups.count) * 100)

    }

    #export log to csv
    $Logs | Export-CSV -Path $path_ -NoTypeInformation #-Encoding UTF8

    #visual info of termination
    Write-Host "Finished!"
    Write-Host "This window will now close!"
    Pause

}else {

    #null or empty path Provided
    Write-Host "Invalid path provided"
    Write-Host "Exiting"
    Pause
}
