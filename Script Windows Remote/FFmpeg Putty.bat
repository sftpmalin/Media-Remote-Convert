@echo off
set SERVER_IP=192.168xxxxxxxxxxxxx
set USER=user xxxxxxxxxxxxxxx
set KEY_PATH=votre clexxxxx
set SESSION_NAME="votre profile session"
set PUTTY_PATH="C:\Program Files (x86)\Putty 0.79\Putty 0.79 x64\putty.exe"

start "" %PUTTY_PATH% -load %SESSION_NAME% -ssh %USER%@%SERVER_IP% -i "%KEY_PATH%" -P 22


