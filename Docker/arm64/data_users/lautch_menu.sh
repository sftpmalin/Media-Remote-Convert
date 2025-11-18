#!/usr/bin/env bash
# ================================================================
# 🚀 Launcher Linux/Mac → Menu Python dans ton Docker FFmpeg
# ================================================================

SERVER="192.168.1.25"
USER="yoan"
KEY="$HOME/.ssh/yoan"     # même clé que dans le .bat

echo ""
echo "Connexion à $SERVER ..."
echo "Clé utilisée : $KEY"
echo ""

# -t : force un terminal interactif
# bash -lc : charge l'environnement (.bashrc)
# export TERM=xterm : indispensable pour clear, tmux, input()
ssh -t -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no "$USER@$SERVER" \
    "bash -lc 'export TERM=xterm; cd ~/scripts; clear; bash menu.sh'"

echo ""
echo "===================================================="
echo "  Fin du menu — session SSH terminée"
echo "===================================================="
