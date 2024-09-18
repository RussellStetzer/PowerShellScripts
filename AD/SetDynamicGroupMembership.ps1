$Groups = Import-CSV -Path C:\Temp\GroupExport.csv
foreach ($Group in $Groups)
{
    if ((get-mggroup -groupid $Group.ID).MembershipRule -match $group.Membershiprule)
    {
        Write-Output "No update for "$group.DisplayName
    }
    else
    {
        update-mggroup -GroupID $group.ID -MembershipRule $group.Membershiprule | Write-Output
        Write-Output "Updating " $Group.DisplayName
    }
}