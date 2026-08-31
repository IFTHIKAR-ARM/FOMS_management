Start-Transcript -Path "c:\xampp\htdocs\FOMS\foms_app\perms_log.txt"

Write-Output "Creating directory D:\VirtualBox..."
if (-not (Test-Path "D:\VirtualBox")) {
    New-Item -ItemType Directory -Path "D:\VirtualBox" -Force
}

Write-Output "Setting strict permissions on D:\VirtualBox..."
icacls "D:\VirtualBox" /reset /c
icacls "D:\VirtualBox" /inheritance:d /c
icacls "D:\VirtualBox" /grant "*S-1-5-32-545:(OI)(CI)(RX)" /c
icacls "D:\VirtualBox" /deny "*S-1-5-32-545:(OI)(CI)(DE,WD,AD,WEA,WA)" /c
icacls "D:\VirtualBox" /grant "*S-1-5-11:(OI)(CI)(RX)" /c
icacls "D:\VirtualBox" /deny "*S-1-5-11:(OI)(CI)(DE,WD,AD,WEA,WA)" /c

Write-Output "Permissions successfully set."
Stop-Transcript
