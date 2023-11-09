$ComputerList = Import-Csv -path C:\Temp\Computers.csv

ForEach ($Computer in $ComputerList){
    $Computer | Select-Object *, @{Name=’PrimaryUsers‘;Expression={[string]::join(“;”, ((Get-CMUserDeviceAffinity -DeviceName $Computer.NetBios_Name).UniqueUserName))}} | Export-Csv C:\Temp\IE_Metering_PrimaryUsers.csv -Append
}
