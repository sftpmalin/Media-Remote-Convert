#!/bin/bash

# ============================================================
# SCRIPT CONNECT_PUTTY.SH - VERSION ECHO (INFAILLIBLE)
# ============================================================

# 1. Récupération automatique des infos
MY_IP=$(hostname -I | awk '{print $1}')
MY_USER=$(whoami)
MY_KEY_NAME="${MY_USER}_ssh_key.ppk"

echo "------------------------------------------------"
echo "  Génération du fichier connect_Putty.bat"
echo "------------------------------------------------"

# 2. Création du fichier ligne par ligne
# On utilise > pour créer le fichier, puis >> pour ajouter les lignes
# L'utilisation de 'echo' avec des simple quotes ' ' protège les parenthèses.

echo "@echo off" > ~/connect_Putty.bat
echo "REM ===============================================" >> ~/connect_Putty.bat
echo "REM  Configuration PuTTY" >> ~/connect_Putty.bat
echo "REM ===============================================" >> ~/connect_Putty.bat
echo "" >> ~/connect_Putty.bat

echo "set SERVER_IP=$MY_IP" >> ~/connect_Putty.bat
echo "set USER=$MY_USER" >> ~/connect_Putty.bat
echo "set KEY_FILE=$MY_KEY_NAME" >> ~/connect_Putty.bat
echo "" >> ~/connect_Putty.bat

echo "REM --- CHEMINS ---" >> ~/connect_Putty.bat
echo "set KEY_PATH=%USERPROFILE%\.ssh\%KEY_FILE%" >> ~/connect_Putty.bat
echo "set SESSION_NAME=\"debian\"" >> ~/connect_Putty.bat

# ICI C'EST LA LIGNE QUI POSAIT PROBLEME
# Les simples quotes ' ' empêchent Bash de lire (x86) comme une commande
echo 'set PUTTY_PATH="C:\Program Files (x86)\Putty 0.79\Putty 0.79 x64\putty.exe"' >> ~/connect_Putty.bat

echo "" >> ~/connect_Putty.bat
echo "REM --- LANCEMENT ---" >> ~/connect_Putty.bat
echo "echo Connexion à %SERVER_IP%..." >> ~/connect_Putty.bat
echo 'start "" %PUTTY_PATH% -load %SESSION_NAME% -ssh %USER%@%SERVER_IP% -i "%KEY_PATH%" -P 22' >> ~/connect_Putty.bat
echo "exit" >> ~/connect_Putty.bat

echo "✅ Terminé ! Fichier connect_Putty.bat créé sans erreur."
