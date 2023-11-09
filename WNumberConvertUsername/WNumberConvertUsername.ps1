$WNumList = Import-Csv "C:\Temp\GraduationLists202210.csv"

ForEach ($CurrentWNum in $WNumList.ID){
    Get-ADUser -Filter {employeeNumber -like $CurrentWNum} -Properties * | Select employeeNumber, sn, givenName, sAMAccountName, mail | Export-Csv -Append "C:\Temp\GraduationLists202210-Export.csv"
}