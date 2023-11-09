<#
.Synopsis
    Detects broken DCM installs
.DESCRIPTION
    Searches WMI to verify it is intact due to build upgrades or new features in DCIM.  If not, remediate.
.EXAMPLE
   
#>

#Variables to test WMI and DCIM
$BIOSElementTest = Get-WmiObject -Namespace 'Root\DCIM\SYSMAN' -Class 'DCIM_BIOSElement' -ErrorAction SilentlyContinue

# Check WMI to see if was a build upgrade and lost DCIM
if ($BIOSElementTest) { $true }