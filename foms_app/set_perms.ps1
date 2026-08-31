Start-Transcript -Path "c:\xampp\htdocs\FOMS\foms_app\perms_log.txt" -Append

Write-Output "Starting permission updates..."

if (-not (Test-Path "D:\programfiles\oracle\VirtualBox")) {
    Write-Output "Creating directory D:\programfiles\oracle\VirtualBox"
    New-Item -ItemType Directory -Path "D:\programfiles\oracle\VirtualBox" -Force
}

# Apply non-inheritable Deny rules to parent folders
Write-Output "Setting permissions on D:\programfiles..."
icacls "D:\programfiles" /deny "*S-1-5-32-545:(DE,WD,AD,WEA,WA)" /c
icacls "D:\programfiles" /deny "*S-1-5-11:(DE,WD,AD,WEA,WA)" /c

Write-Output "Setting permissions on D:\programfiles\oracle..."
icacls "D:\programfiles\oracle" /deny "*S-1-5-32-545:(DE,WD,AD,WEA,WA)" /c
icacls "D:\programfiles\oracle" /deny "*S-1-5-11:(DE,WD,AD,WEA,WA)" /c

# Apply strict permissions on VirtualBox destination folder
Write-Output "Setting permissions on D:\programfiles\oracle\VirtualBox..."
icacls "D:\programfiles\oracle\VirtualBox" /inheritance:d /c
icacls "D:\programfiles\oracle\VirtualBox" /grant "*S-1-5-32-545:(OI)(CI)(RX)" /c
icacls "D:\programfiles\oracle\VirtualBox" /deny "*S-1-5-32-545:(OI)(CI)(DE,WD,AD,WEA,WA)" /c
icacls "D:\programfiles\oracle\VirtualBox" /grant "*S-1-5-11:(OI)(CI)(RX)" /c
icacls "D:\programfiles\oracle\VirtualBox" /deny "*S-1-5-11:(OI)(CI)(DE,WD,AD,WEA,WA)" /c

Write-Output "Permission updates finished."
Stop-Transcript
