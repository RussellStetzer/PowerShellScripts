<#
   .SYNOPSIS
        This script will automatically find on-prem AD objects and move them to a desired location ata certain age back specified.
   .EXAMPLE
        Disable-MoveOldADComputers.ps1 -WhatIf $False -DesiredDate 180 -SearchBaseOU "OU=Something,OU=Must,OU=Go,OU=In,DC=Here,DC=edu"
   .PARAMETER 
        -WhatIf is required if you want the script to take any action (use $False to override).  This was set up for a fail safe to force the technician to override.
   
   .SYNTAX
   .NOTES
        $OSManufacturer is only set to WINDOWS since this is a script just for the PC side of the house for now
        $AppendDescription I have not set as a parameter for now since we'd like to keep this standardized

        $We can add any new $ObjectResult to add better verbose output logs on action by simply adding a new line in the Hash Table
    .LINK
#>

Param(
    [Parameter(Mandatory=$False,
        HelpMessage="Default is always set to True, must override to allow script to take action setting it to `$False")]
    $WhatIfTest = "$True",
    
    [Parameter(Mandatory=$False,
        HelpMessage="Todays date minus input")]
    [string] $DesiredDate = "365",

    [Parameter(Mandatory=$False,
        HelpMessage="OU for script to scan to find old objects")]
    [string]$SearchBaseOU = "OU=Test,DC=edu",

    [Parameter(Mandatory=$False,
        HelpMessage="OU to disable, label, and move objects")]
    [string]$MoveTargetOU = "OU=zAudit,OU=Test,DC=edu",

    [Parameter(Mandatory=$False,
        HelpMessage="Check if ConfigMgr client exists or not")]
    $ConfigMgrClientAudit = "$False"
)

Try {
    
    #Ignore any keywords in the Distinguished Name
    $IgnoreOUs = @(
    "*Delete*", 
    "*Audit*")
       
    $DateCutOff = (Get-Date).AddDays(-($DesiredDate))
    $OSManufacturer = "Windows*"

    $OutputFileLocation = "C:\Temp\"
    $OutputFileName = "AD-Object-Cleanup.csv"
    $OutputFile = $OutputFileLocation + $OutputFileName

    $AppendDescription = "Automated script" + " - " + (Get-date -Format yyyy/MM/dd)

    #Reasons for moving or not
    $OutputResult = [PSCustomObject]@{
        "OUIgnore"        = "Object in ignore OU"   
        "OSIgnore"        = "Object is ignored OS"  
        "CMExists"        = "ConfigMgr Client Exists"
        "CMIgnore"        = "ConfigMgr Check Ignored"
        "Move"            = "Object moved"            
    }

    $OldObjects = Get-ADComputer -SearchBase $SearchBaseOU -Filter {PasswordLastSet -lt $datecutoff} -Property Name, DistinguishedName, Description, OperatingSystem, PasswordLastSet | Select Name, DistinguishedName, Description, OperatingSystem, PasswordLastSet

    $Results = @()
    $ObjectResult = @()

    #Get current computer and audit location
    ForEach ($CurrentComputer in $OldObjects){
    
        #Declare new object
        $ObjectResult = [PSCustomObject]@{
            "ComputerName"      = $CurrentComputer.Name
            "IgnoreByOU"        = ""
            "IgnoreByOS"        = ""
            "CMClientExists"    = ""
            "Description"       = $CurrentComputer.Description
            "DistinguishedName" = $CurrentComputer.DistinguishedName
            "PasswordLastSet"   = $CurrentComputer.PasswordLastSet
            "MoveSuccess"       = ""
        }

        #Reset variable to ignore the current object before starting the loop
        $FlagIgnore = $false

        #Check statements for the various reasons we are moving or not
        ForEach ($CurrentIgnoreOU in $IgnoreOUs){
            If ($CurrentComputer.DistinguishedName -like $CurrentIgnoreOU){
                $FlagIgnore = $True
                $ObjectResult.IgnoreByOU = $OutputResult.OUIgnore
            }
        }

        If ($CurrentComputer.OperatingSystem -notlike $OSManufacturer){
            $FlagIgnore = $True
            $ObjectResult.IgnoreByOS = $OutputResult.OSIgnore
        }

        If ($ConfigMgrClientAudit -eq $True){
            # Site configuration
            $SiteCode = "WWU" # Site code 
            $ProviderMachineName = "sccmfe1.univ.dir.wwu.edu" # SMS Provider machine name

            # Customizations
            $initParams = @{}
            #$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
            #$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

            # Do not change anything below this line

            # Import the ConfigurationManager.psd1 module 
            if((Get-Module ConfigurationManager) -eq $null) {
                Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
            }

            # Connect to the site's drive if it is not already present
            if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
                New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
            }

            # Set the current location to be the site code.
            Set-Location "$($SiteCode):\" @initParams

            $CheckExists = Get-CMDevice -Name $CurrentComputer.Name | Select Name, IsClient
            
            If ($CheckExists.IsClient -eq 'True'){
                $FlagIgnore = $True
                $ObjectResult.CMClientExists = $OutputResult.CMExists
            }
            
        }
        Else{
            $ObjectResult.CMClientExists = $OutputResult.CMIgnore
        }

        If (!$FlagIgnore){
            $DistName = $CurrentComputer.DistinguishedName

            #Modify all attributes that are needed
            If (!$WhatIfTest){
                Set-ADComputer -Identity $DistName -Enabled $false

                If ($CurrentComputer.Description -eq $null){
                    $SetNewDescription = $AppendDescription
                }
                Else {
                    $SetNewDescription = $CurrentComputer.Description + " - " + $AppendDescription
                }
                Set-ADComputer -Identity $DistName -Description $SetNewDescription

                Move-ADObject -Identity $DistName -TargetPath $MoveTargetOU -Verbose
            }
            $ObjectResult.MoveSuccess = $OutputResult.Move
        }
       
        $Results += $ObjectResult
        
    }

    If (!(Test-Path -Path $OutputFileLocation)){
        New-Item -ItemType Directory -Path $OutputFileLocation -Confirm:$False -Force
    }

    Write-Output $Results
    $Results | Export-Csv -Path $OutputFile -NoTypeInformation
}

Catch {

    $TestAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

    If (Get-Process "EXCEL" -ErrorAction SilentlyContinue) {
        Write-Output "Excel is in use"
    }
    ElseIf (!$TestAdmin){
        Write-Output "You're not running this script as an Administrator"
    }
    Else{
        Write-Output "Generic error, check OU pathing"
    }
}