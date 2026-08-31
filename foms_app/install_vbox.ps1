Start-Transcript -Path "c:\xampp\htdocs\FOMS\foms_app\install_run_log.txt"

Write-Output "Starting VirtualBox MSI installation..."

$msiPath = "c:\xampp\htdocs\FOMS\foms_app\vbox_extract\VirtualBox-7.2.10-r174163-MultiArch_amd64.msi"
$logPath = "c:\xampp\htdocs\FOMS\foms_app\install_log.txt"
$installDir = "D:\VirtualBox\"

Write-Output "MSI Path: $msiPath"
Write-Output "Log Path: $logPath"
Write-Output "Install Dir: $installDir"

# Run msiexec
$p = Start-Process msiexec.exe -ArgumentList "/i", "`"$msiPath`"", "INSTALLDIR=`"$installDir`"", "/qn", "/norestart", "/l*v", "`"$logPath`"" -PassThru -Wait

Write-Output "MSI exit code: $($p.ExitCode)"

Stop-Transcript
