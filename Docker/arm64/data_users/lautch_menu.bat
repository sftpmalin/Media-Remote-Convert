@echo off
title MENU Bash - Docker FFmpeg
mode con: cols=140 lines=40

REM ===============================================
REM  Connexion SSH + lancement du menu Python
REM ===============================================

set SERVER=192.168.1.25
set USER=yoan
set KEYPATH=%USERPROFILE%\.ssh\yoan

echo.
echo Connexion à %SERVER% ...
echo (Assure-toi que la clé %KEYPATH% est présente)
echo.

ssh -t -i "%KEYPATH%" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no %USER%@%SERVER% ^
    "bash -lc 'export TERM=xterm; cd ~/scripts; clear; bash menu.sh'"

echo.
echo ===============================================
echo   Menu terminé - Session SSH fermée
echo ===============================================
exit
