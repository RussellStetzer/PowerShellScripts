#Gather faulty scheduled tasks
$task = Get-ScheduledTask | where TaskPath -match 'EnterpriseMgmt' | select TaskPath | Select-String -Pattern [0-9] | Get-Unique
$task = $task.ToString()
$task = $task.Substring($task.length -38, 36)

#Gather all registry enrollment IDs
$registrykey = Get-Item HKLM:\SOFTWARE\Microsoft\Enrollments\* | select Name, PSChildName

#Remove Intune Enrollment scheduled tasks
Get-ScheduledTask | where TaskPath -match 'EnterpriseMgmt' | Unregister-ScheduledTask -Confirm:$false

#Clean up registry that matches scheduled task ID
foreach ($Value in $registrykey){
    if ($Value.PSChildName -eq $task){
        $RegToRemove = $Value.PSChildName
        Remove-Item HKLM:\SOFTWARE\Microsoft\Enrollments\$RegToRemove -Recurse -Force -Verbose
    }
}

$applicationlist =@("*Intune*, *Configuration Manager*")
$results = @()
$reglocations = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")

foreach($location in $reglocations)
    {
        foreach($application in $applicationlist)
        {
            $results += (Get-ChildItem -Path $location | Get-ItemProperty | Where-Object {$_.DisplayName -like $application} | Select-Object -Property DisplayName, PSChildName, Version)
        }
    }
    
foreach($UnInstall in $results)
    {
                
        $MSIArguments = @(
        '/x'
        $UnInstall.PSChildName
        '/qn'    
        '/L*v "C:\Windows\Temp\' + $($UnInstall.DisplayName)+'.log"'
        'REBOOT=REALLYSUPPRESS'
        )
               
        $Uninstaller = Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow -ErrorAction Stop -PassThru
                    
    }

# Remove SCCM.CP from system
Remove-LocalGroupMember -Group "Administrators" -Member "WWU\SCCM.CP" -Confirm:$false -ErrorAction SilentlyContinue -Verbose

# Stop CCMExec sevice
Stop-Service -Name CcmExec -Force -Confirm:$false -ErrorAction SilentlyContinue

#Unregister the scheduled SCCM health script task
Unregister-ScheduledTask -TaskName "SCCM Client Health Monitor" -Confirm:$false

# Launch uninstaller
Start-Process -FilePath "$env:windir\ccmsetup\ccmsetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue -Verbose

#Remove directories if left
Remove-Item -Path "$ENV:WinDir\CCMSetup" -Force -Confirm:$false
Remove-Item -Path "$ENV:WinDir\CCMTemp" -Force -Confirm:$false

#Remove WU/ConfigMgr registry settings from ConfigMgr
Remove-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Recurse -Force
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\CCM' -Recurse -Force
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\CCMSetup' -Recurse -Force
Remove-Item -Path "$env:windir\System32\GroupPolicy\Machine\Registry.Pol" -Force

#hangs since it's using this folder to run the script
#Remove-Item -Path "$ENV:WinDir\CCM" -Force -Confirm:$false
#Remove-Item -Path "$ENV:WinDir\CCMCache" -Force -Confirm:$false 
