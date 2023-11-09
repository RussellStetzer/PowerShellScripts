Param(
    [Parameter(Mandatory=$True)]
    [string]$FolderPath = "C:\_SMSTaskSequence"
)

Try {
    Remove-Item -Path $FolderPath -Recurse -Force
}
Catch {
    Write-Output "Failed to remove $FolderPath from remote computer"
}