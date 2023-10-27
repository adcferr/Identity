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

#get number of devices per user and user assigned set role

#region Functions

#? Menu Function Source: https://community.spiceworks.com/scripts/show/4656-powershell-create-menu-easily-add-arrow-key-driven-menu-to-scripts #
Function Create-Menu (){
    
    Param(
        [Parameter(Mandatory=$True)][String]$MenuTitle,
        [Parameter(Mandatory=$True)][array]$MenuOptions
    )

    $MaxValue = $MenuOptions.count-1
    $Selection = 0
    $EnterPressed = $False
    
    Clear-Host

    While($EnterPressed -eq $False){
        
        Write-Host "$MenuTitle"

        For ($i=0; $i -le $MaxValue; $i++){
            
            If ($i -eq $Selection){
                Write-Host -BackgroundColor Cyan -ForegroundColor Black "[ $($MenuOptions[$i]) ]"
            } Else {
                Write-Host "  $($MenuOptions[$i])  "
            }

        }

        $KeyInput = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown").virtualkeycode

        Switch($KeyInput){
            13{
                $EnterPressed = $True
                Return $Selection
                Clear-Host
                break
            }

            38{
                If ($Selection -eq 0){
                    $Selection = $MaxValue
                } Else {
                    $Selection -= 1
                }
                Clear-Host
                break
            }

            40{
                If ($Selection -eq $MaxValue){
                    $Selection = 0
                } Else {
                    $Selection +=1
                }
                Clear-Host
                break
            }
            Default{
                Clear-Host
            }
        }
    }
}
#endregion Functions


#? connect Azure Ad
 Connect-AzureAD
 Connect-MgGraph -Scopes "Directory.ReadWrite.All"



#region Initialization
$Logs = @()
$pgBar = 0
$numberOfUserDevices = 0

Clear-Host

#? iinitialize empty list of admin roles to test users against
$adminRole = @()

#endregion Initialization

#region Menu

$option = Create-Menu -MenuTitle "Select Source" -MenuOptions ("Manually Set Admin Roles","Import Admin Roles from .txt","Use default Global Admin only")

switch ( $option )
{
    "0" { 
        $howManyRolesToCreate = Read-Host "How many roles "
        for($x = 0; $x -lt $howManyRolesToCreate; $x++){
            $roleToAdd = Read-Host "Role Name:"

            #? check for null or empty values entered
            if(!([string]::IsNullOrEmpty($roleToAdd))){ $adminRole += $roleToAdd } else { Write-Error "Empty or null value verified!" -ErrorAction Stop }
        }
     }
    "1" { 

        Write-Host "Select source .txt file "
        #? set OpenFileDialog
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog

        #? path for txt list file
        $response = $OpenFileDialog.ShowDialog()
        if ($response -eq "OK"){

            #? get selected file fullpath
            $roleListToCheck_path =  $OpenFileDialog.filename
        } else {

            #? if no file is selected
            Write-Error "No file selected! Exiting..." -ErrorAction Stop

        }        

        #? get values from file
        $roleListToCheck = Get-Content $roleListToCheck_path

        #? make sure we have values and not null or empty
        if(!([string]::IsNullOrEmpty($roleListToCheck))){

            #= cycle through all lines geting all values
            foreach($line in $roleListToCheck) {
                
                #? check if line is null or empty if not add value to setadmin roles array
                if(!([string]::IsNullOrEmpty($line))){ $adminRole += $line }
            }        
        } else {

            #? if file is empty break script
            Write-Error "No info on file or error reading file!Exiting..." -ErrorAction Stop
        }
     }
    "2" { 
        $adminRole = @("Global Administrator")
     }
    default { 

    #? Fully stop script
    Write-Error "Invalid selection!Exiting..." -ErrorAction Stop

    }
}

#endregion  Menu

Write-Host "Aquiring Roles..."
#? get all roles set in AAD
$templateRoles = Get-AzureADMSRoleDefinition  

Write-Host "Aquiring Users..."
#? Get users from AAD
$allUsers = Get-AzureAdUser

#? request path to save csv file
$path = Read-Host "Enter full CSV file name with Path (ex: C:\user\abc\desktop\myfile.CSV)" 

#region cycle users

#? if path to save file is not null or empty
if (!([string]::IsNullOrEmpty($path))) {

    #check if file has CSV extension
    $testCsv = ($path.substring($path.length -4))

    #if filename does not have .csv extension add it to name
    if ($($testCsv.Tolower) -ne ".csv") {
        $path += ".csv"
    }

    #? Loop users
    foreach ($user in $allUsers) {

        #? Create Log info
        $Log = New-Object System.Object

        #? 1st colunm of CSV with User Displayname
        $Log | Add-Member -MemberType NoteProperty -Name "Name" -Value $user.DisplayName

        #? reset var to 0
        $numberOfUserDevices = 0

        #? get all devices assigned to current user
        $devices = Get-AzureADUserRegisteredDevice -ObjectId $user.ObjectId

        if (!([string]::IsNullOrEmpty($devices))) {

            #? Get the number of devices associated with the user
            $numberOfUserDevices = $devices.Count

        }
        
        #? 2� colunm of CSV with Number of user devices
        $Log | Add-Member -MemberType NoteProperty -Name "NumberOfAssignedDevices" -Value $numberOfUserDevices

        ##? make request
        $response = $null    
        
        ##NOTE##
        #**************************************************************************************************************************************************        
        #? TransitiveRoleAssignments is in testing and may be discontinued , if so please uncomment the bellow line of code and comment the one bellow it.
        # Bear in mind that changing this, the roles assigned indirectly will not be check.

        #$uri = "https://graph.microsoft.com/beta/roleManagement/directory/RoleAssignments?`$count=true&`$filter=principalId eq `'$($user.ObjectId)`'"
        $uri = "https://graph.microsoft.com/beta/roleManagement/directory/transitiveRoleAssignments?`$count=true&`$filter=principalId eq `'$($user.ObjectId)`'"
        
        #**************************************************************************************************************************************************        
        
        $method = 'GET'
        $headers = @{'ConsistencyLevel' = 'eventual'}
        #? store request
        $response = (Invoke-MgGraphRequest -Uri $uri -Headers $headers -Method $method -Body $null).value
      
        #? list of roles assing
        $roles=@()

        #? check for null or empty role response
        if (!([string]::IsNullOrEmpty($response.roleDefinitionId))) {

            #? cycle trought assigned roles
            foreach($role in $response){

                #? from assigned role Id get the Dysplayname From all roles list
                foreach($row in $templateRoles){
    
                    if($role.roleDefinitionId -eq $row.Id) { $roles += $row.DisplayNAme }
                }  
            }
        }

        #? list of Roles to write to log (only write to log roles set as admin)
        $writeRolestoLog=@()

        #? Set $adminroles is already checked in the Menu section no need to repeat the check

        #? check if user as assigned role set in admin roles list
        foreach($assignedRole in $roles){

            #? cycle list of roles set as admin for comparison
            foreach($line in $adminRole){

                #? if current role is set as admin role in list add for logging
                if($assignedRole -eq $line){ $writeRolestoLog += $line }
            }
        }

        #remove possibility of duplicates since we check direcly and inderctly assigned roles
        $writeRolestoLog = $writeRolestoLog | sort -Unique

        #? transform array to string for output on CSV table
        [string]$writeRolestoLog_String = $writeRolestoLog -join " \ "

        #? 3� colunm of CSV with assigned Admin Roles
        $Log | Add-Member -MemberType NoteProperty -Name "AssignedAdminRoles" -Value $writeRolestoLog_String

        #? PGBarr progress layout
        $pgBar++
        Write-Progress -Activity 'Processing Users' -CurrentOperation $user.DisplayName -PercentComplete (($pgBar / $allUsers.count) * 100)
        
        #? add all user info to final Log
        $Logs += $Log

    }
}
#endregion cycle users

#export log to csv
$Logs | Export-CSV -Path $path -NoTypeInformation -Encoding UTF8

#visual info of termination
Write-Host "Finished!"
Pause