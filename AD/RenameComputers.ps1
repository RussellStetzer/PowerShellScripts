<#
   .SYNOPSIS
        This script will automatically rename computers in a CSV file list
   .EXAMPLE
        RenameComputers.ps1
   .PARAMETER 
        None   
   .SYNTAX
   .NOTES
        Verify the CompList.csv is in the correct pathing below
	    Run file from command line or in ISE/Visual Studio
        Input admin credentials as domain\username
        Verify CSV is as follows with 2 columns, first column CurrentName, second column NewName as shown below. 
            CurrentName	    NewName
            ATUS-1CB29H2	ATUS-W-1CB29H2
   .LINK
#>

$OutputResult = [PSCustomObject]@{
    "UserLoggedIn"    = "User Logged in"   
    "SystemOffline"   = "System is Offline"  
    "RenameSuccess"   = "Rename Successful"
    "Other"           = "Failed"
}

$CompList = Import-Csv "C:\Temp\CompList.csv"
$OutputFileLocation = "C:\Temp\"
$OutputFileName = "RenameResults" + " - " + ((Get-Date).ToString("HHmmss")) + ".csv"
$OutputFile = $OutputFileLocation + $OutputFileName

$Results = @()
$ObjectResult = @()

$Creds = Get-Credential

Try{
    Foreach ($CurrentComputer in $CompList){
        $ObjectResult = [PSCustomObject]@{
                "CurrentName"      = $CurrentComputer.CurrentName
                "NewName"          = $CurrentComputer.NewName
                "Results"          = ""
        }
        #Check if system is online, else just output results
        if (Test-Connection -ComputerName $CurrentComputer.CurrentName -Count 1 -ErrorAction SilentlyContinue -Verbose){
            #If online, check for a current user, else just output to results
            if(!"quser /SERVER:$CurrentComputer.CurrentName"){
                $TryRename = Rename-Computer -ComputerName $CurrentComputer.CurrentName -NewName $CurrentComputer.NewName -DomainCredential $creds -Confirm:$False -Force -PassThru -Restart -Verbose
                #Verify object renamed, else just output to results
                if ($TryRename){
                    $ObjectResult.Results = $OutputResult.RenameSuccess
                }
                else {
                    $ObjectResult.Results = $OutputResult.Other
                }
            }
            else {
                $ObjectResult.Results = $OutputResult.UserLoggedIn
            }
        }
        else {
            $ObjectResult.Results = $OutputResult.SystemOffline
        }
        $Results += $ObjectResult
    }
    #Check to make sure output path exists, if not, create it
    If (!(Test-Path -Path $OutputFileLocation)){
        New-Item -ItemType Directory -Path $OutputFileLocation -Confirm:$False -Force
    }
    #Export all data
    $Results | Export-Csv -Path $OutputFile -NoTypeInformation
}

Catch {
    If (Get-Process "EXCEL" -ErrorAction SilentlyContinue) {
        Write-Output "Excel is in use"
    }
    else {
        Write-Output "Unknown Error"
    }
}