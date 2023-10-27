#################################################################################
#DISCLAIMER: This is not an official PowerShell Script. We designed it specifically for the situation you have encountered right now.
#Please do not modify or change any preset parameters. 
#Please note that we will not be able to support the script if it is changed or altered in any way or used in a different situation for other means.
#This code sample is provided "AS IT IS" without warranty of any kind, either expressed or implied, including but not limited to the implied warranties of merchantability and/or fitness for a particular purpose.
#This sample is not supported under any Microsoft standard support program or service.. 
#Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
#The entire risk arising out of the use or performance of the sample and documentation remains with you. 
#In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, 
#or other pecuniary loss) arising out of  the use of or inability to use the sample or documentation, even if Microsoft has been advised of the possibility of such damages.
#################################################################################

## users per device

Clear-Host

#? connect Azure Ad
Connect-AzureAD

$pgBar = 0
$pgBar_ = 0
$Logs  = @()

#? get all users
$allUsers = Get-AzureAdUser -all $true

$userObjsArray =@()

$uniqueDeviceList = @()

#? request path to save csv file
$path = Read-Host "Enter full CSV file name with Path (ex: C:\user\abc\desktop\myfile.CSV)" 

#? if path to save file is not null or empty
if (!([string]::IsNullOrEmpty($path))) {

    #check if file has CSV extension
    $testCsv = ($path.substring($path.length -4))

    #if filename does not have .csv extension add it to name
    if ($($testCsv.Tolower) -ne ".csv") {
        $path += ".csv"
    }

    foreach($user in $allUsers){

        #? get all devices assigned to user by id
        [array]$devicePerUser = Get-AzureADUserRegisteredDevice -ObjectId $user.ObjectId  
        
        #? cycle trought all devices in user and for each device create a row with assigned username | devicename
        foreach($deviceName in $devicePerUser){
    
            #? create obj list
            $obj = New-Object System.Object
    
             #? 1st colunm of CSV with User Displayname
             $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $user.DisplayName
    
             #? 1st colunm of CSV with User Displayname
             $obj | Add-Member -MemberType NoteProperty -Name "Devices" -Value $deviceName.DisplayName #
    
             #? create list of device names for 2nd loop
             $uniqueDeviceList += $deviceName.displayName
    
             #? buildup log of users and assigned devices
            $userObjsArray += $obj
    
        }      
    
        #? PGBarr progress layout
        $pgBar++
        Write-Progress -Activity 'Processing Users' -CurrentOperation $user.DisplayName -PercentComplete (($pgBar / $allUsers.count) * 100)
    
    }

    #? list of all device ready
    $uniqueDeviceList = $uniqueDeviceList | Sort -Unique

    #? cycle trhought unique all devices list 
    foreach($device in $uniqueDeviceList) {

        #? create log for final report
        $Log = New-Object System.Object

        #? 1st colunm of CSV with Udevice name
        $Log | Add-Member -MemberType NoteProperty -Name "Device" -Value $device

        #? empty list of users assigned to device
        $usersAssignedToDevice = @()

        #? for each unique device we need to cycle throught users 
        foreach($line in $userObjsArray){

            #? if current checking device matches device being checked from unique 
            #list we assign user to device in final list and break cycle
            if($line.Devices -eq $device){ $usersAssignedToDevice += $line.Name }
            
        }
        #? sort unique 
        $usersAssignedToDevice = $usersAssignedToDevice | sort -Unique

        #? join array in single string
        [string]$usersAssignedToDevice_String = $usersAssignedToDevice -join " \ "

        #? 1st colunm of CSV with User 
        $Log | Add-Member -MemberType NoteProperty -Name "AssignedUsers" -Value $usersAssignedToDevice_String

        #? increment logs
        $Logs += $Log

        #? PGBarr progress layout
        $pgBar_++
        Write-Progress -Activity 'Processing Devices' -CurrentOperation $device -PercentComplete (($pgBar_ / $uniqueDeviceList.count) * 100)

    }
}

#export log to csv
$Logs | Export-CSV -Path $path -NoTypeInformation -Encoding UTF8

#visual info of termination
Write-Host "Finished!"






