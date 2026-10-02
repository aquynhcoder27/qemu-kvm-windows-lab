@echo off
setlocal
net session >nul 2>&1
if errorlevel 1 (
  echo Run this script in an elevated Command Prompt.
  exit /b 1
)

netsh advfirewall firewall delete rule name="Lab ICMPv4 Echo" >nul 2>&1
netsh advfirewall firewall add rule name="Lab ICMPv4 Echo" dir=in action=allow protocol=icmpv4:8,any remoteip=192.168.122.0/24 profile=any
if errorlevel 1 exit /b 1

echo ICMPv4 echo is allowed from the lab subnet.
exit /b 0
