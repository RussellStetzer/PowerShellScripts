# Install-Module Microsoft.Graph -Scope AllUsers
# Install-Module Microsoft.Graph.Beta -Scope AllUsers
# Connect-MgGraph

Get-MgGroup -filter "startswith(displayname, 'device') and groupTypes/any(c:c eq 'DynamicMembership')" -All | select ID, DisplayName, Membershiprule | Export-Csv C:\Temp\GroupExport.csv -NoTypeInformation