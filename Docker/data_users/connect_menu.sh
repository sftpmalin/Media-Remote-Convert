#!/bin/bash

# ============================================================
# SCRIPT CONNECT.SH (VERSION FINALE PROPRE)
# ============================================================

# 1. Récupération automatique des infos du serveur
MY_IP=$(hostname -I | awk '{print $1}')
MY_USER=$(whoami)
MY_KEY_NAME="${MY_USER}_ssh_key"

echo "------------------------------------------------"
echo "  Génération des fichiers de connexion."
echo "  Ils seront placés dans : ~/ ($HOME)"
echo "------------------------------------------------"

# ------------------------------------------------------------
# 2. Création du fichier WINDOWS (.bat) -> DANS LA RACINE HOME (~)
# ------------------------------------------------------------
cat <<EOF > ~/connect_windows.bat
@echo off
title MENU Bash - Docker FFmpeg
mode con: cols=140 lines=40

REM ===============================================
REM  Connexion SSH + lancement du menu Python
REM ===============================================

set SERVER=$MY_IP
set USER=$MY_USER
set KEYPATH=%USERPROFILE%\\.ssh\\$MY_KEY_NAME

echo.
echo Connexion à %SERVER% ...
echo Clé utilisée : %KEYPATH%
echo.

ssh -t -i "%KEYPATH%" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no %USER%@%SERVER% ^
    "bash -lc 'export TERM=xterm; cd ~/scripts; clear; bash menu.sh'"

echo.
echo ===============================================
echo    Menu terminé - Session SSH fermée
echo ===============================================
pause
exit
EOF

# ------------------------------------------------------------
# 3. Création du fichier LINUX (.sh) -> DANS LA RACINE HOME (~)
# ------------------------------------------------------------
cat <<EOF > ~/connect_linux.sh
#!/usr/bin/env bash
# ================================================================
# 🚀 Launcher Linux/Mac
# ================================================================

SERVER="$MY_IP"
USER="$MY_USER"
KEY="\$HOME/.ssh/$MY_KEY_NAME"

echo ""
echo "Connexion à \$SERVER ..."
echo "Clé utilisée : \$KEY"
echo ""

ssh -t -i "\$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no "\$USER@\$SERVER" \\
    "bash -lc 'export TERM=xterm; cd ~/scripts; clear; bash menu.sh'"

echo ""
echo "===================================================="
echo "  Fin du menu — session SSH terminée"
echo "===================================================="
EOF
# On rend le script Linux exécutable
chmod +x ~/connect_linux.sh

# ------------------------------------------------------------
# 4. Création du fichier PERMISSIONS (permissions_Windows.bat) -> DANS LA RACINE HOME (~)
# ------------------------------------------------------------
cat <<EOF > ~/permissions_Windows.bat
@echo off
title Reparation Droits SSH Windows
mode con: cols=100 lines=30

echo.
echo ========================================================
echo  REPARATION DES DROITS DU DOSSIER .SSH
echo ========================================================
echo.

set SSH_FOLDER=%USERPROFILE%\\.ssh

if not exist "%SSH_FOLDER%" (
    echo ERREUR : Le dossier %SSH_FOLDER% n'existe pas.
    pause
    exit
)

echo Cible : %SSH_FOLDER%
echo.
echo 1. Suppression des droits hérites...
icacls "%SSH_FOLDER%" /inheritance:r /grant:r "%USERNAME%":(OI)(CI)F

echo 2. Attribution du controle total a l'utilisateur %USERNAME%...
icacls "%SSH_FOLDER%" /grant:r "%USERNAME%":F

echo.
echo ========================================================
echo  SUCCES ! Les permissions sont corrigees.
echo ========================================================
pause
exit
EOF

echo "✅ Les 3 fichiers sont maintenant créés et placés dans votre dossier personnel : \$HOME"

