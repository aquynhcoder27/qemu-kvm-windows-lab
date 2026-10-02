@echo off
setlocal
if /I "%PROCESSOR_ARCHITEW6432%"=="AMD64" goto run_in_64_bit_cmd
net session >nul 2>&1
if errorlevel 1 (
  echo Run this script in an elevated Command Prompt.
  exit /b 1
)

set "package=OpenSSH-Win32"
if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "package=OpenSSH-Win64"
if not exist "%~dp0%package%\sshd.exe" (
  echo OpenSSH package %package% is missing from this disc.
  exit /b 2
)

sc query sshd >nul 2>&1
if errorlevel 1 (
  xcopy "%~dp0%package%\*" "%ProgramFiles%\OpenSSH\" /E /I /Y /Q
  if errorlevel 1 exit /b 3
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ProgramFiles%\OpenSSH\install-sshd.ps1"
  sc query sshd >nul 2>&1
  if errorlevel 1 (
    echo The OpenSSH service was not installed.
    exit /b 4
  )
)

sc config sshd start= auto
if errorlevel 1 exit /b 5
net start sshd
sc query sshd | find "RUNNING" >nul
if errorlevel 1 (
  echo The OpenSSH service did not start.
  exit /b 6
)

netsh advfirewall firewall delete rule name="Lab OpenSSH" >nul 2>&1
netsh advfirewall firewall add rule name="Lab OpenSSH" dir=in action=allow protocol=TCP localport=22 remoteip=192.168.122.0/24 profile=any
if errorlevel 1 exit /b 7

call "%~dp0enable-lab-network.cmd"
if errorlevel 1 exit /b 8

"%ProgramFiles%\OpenSSH\ssh.exe" -V
echo OpenSSH installed; TCP 22 and ICMPv4 echo are open to the lab subnet.
exit /b 0

:run_in_64_bit_cmd
"%SystemRoot%\Sysnative\cmd.exe" /c "%~f0"
exit /b %errorlevel%
