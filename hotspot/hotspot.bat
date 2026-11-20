@echo off
rem Double-click to start the hotspot. Edit the name/password below.
set SSID=J5-Hotspot
set PASS=ChangeMe123
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0hotspot.ps1" start -Ssid "%SSID%" -Password "%PASS%" -Band 5
echo.
pause
