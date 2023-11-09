Param(
    [Parameter(Mandatory=$True)]
    [string]$MSICode = "Insert MSI Code (Example: {4282C0BC-3B22-33D4-B72E-62922415DDCB})"
)

Try {
    Start-Process "MsiExec.exe" -ArgumentList "/x $MSICode /qn /norestart /l*v C:\Windows\Temp\$MSICode.log"
}
Catch {
    Write-Output "Failed to to remove installed product from system"
}