$Groups = Import-CSV -Path C:\Temp\GroupExport.csv
foreach ($Group in $Groups)
{  
        update-mggroup -GroupID $group.ID -MembershipRule $group.Membershiprule | Write-Output
        Write-Output "Updating " $Group.DisplayName
}