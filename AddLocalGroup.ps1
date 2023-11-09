Param(
    [Parameter(Mandatory=$True)]
    [string]$ADUserGroupName = "WWU\UserName or WWU\GroupName",
    
    [Parameter(Mandatory=$True)]
    [string] $LocalGroupName = "Administrators"
)

Try {
    Add-LocalGroupMember -Group $LocalGroupName -Member "$ADUserGroupName" -ErrorAction Stop
    Write-Output "Successfully added $ADUserGroupName to $LocalGroupName Group"
}
Catch {
    Write-Output "Failed to add $ADUserGroupName to $LocalGroupName Group"
}