@echo off
set SERVER_IP=192.168.1.25
set USER=yoan
set KEY_PATH=D:\Nextcloud\keys\yoan.ppk
set SESSION_NAME="debian"
set PUTTY_PATH="C:\Program Files (x86)\Putty 0.79\Putty 0.79 x64\putty.exe"

start "" %PUTTY_PATH% -load %SESSION_NAME% -ssh %USER%@%SERVER_IP% -i "%KEY_PATH%" -P 22

