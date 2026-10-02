@echo off
setlocal
net session >nul 2>&1
if errorlevel 1 (
  echo Run this script in an elevated Command Prompt.
  exit /b 1
)

if not exist "%~dp0Windows6.0-KB968930-x64.msu" (
  echo PowerShell 2.0 package is missing from this disc.
  exit /b 2
)

echo Installing Microsoft KB968930 for Windows Server 2008 SP2 x64...
start /wait "" wusa.exe "%~dp0Windows6.0-KB968930-x64.msu" /quiet /norestart
set "result=%errorlevel%"
echo WUSA exit code: %result%
if "%result%"=="0" exit /b 0
if "%result%"=="3010" (
  echo Restart Windows before installing OpenSSH.
  exit /b 0
)
exit /b %result%
