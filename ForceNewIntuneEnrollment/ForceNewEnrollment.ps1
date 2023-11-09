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