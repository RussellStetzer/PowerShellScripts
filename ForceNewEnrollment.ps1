$task = Get-ScheduledTask | where TaskPath -match 'EnterpriseMgmt' | select TaskPath | Select-String -Pattern [0-9] | Get-Unique
$task = $task.ToString()
$task = $task.Substring($task.length -38, 36)

$registrykey = Get-Item HKLM:\SOFTWARE\Microsoft\Enrollments\* | select Name, PSChildName

foreach ($Value in $registrykey){
    if ($Value.PSChildName -eq $task){
        $RegToRemove = $Value.PSChildName
        Remove-Item HKLM:\SOFTWARE\Microsoft\Enrollments\$RegToRemove -Recurse -Force -Verbose
    }
}

gpupdate /force