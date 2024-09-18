$Groups = Import-CSV -Path C:\Temp\GroupExport.csv
foreach ($Group in $Groups)
{
    if ((get-mggroup -groupid $Group.ID).MembershipRule -notmatch $group.Membershiprule)
    {
        update-mggroup -GroupID $group.ID -MembershipRule $group.Membershiprule
    }
}