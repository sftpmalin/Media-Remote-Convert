#!/usr/bin/env python3

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Tuple

# --- Bibliothèques de Menu ---
try:
    import inquirer
except ImportError:
    print("ERREUR : La bibliothèque 'inquirer' n'est pas installée.")
    print("Veuillez l'installer avec : pip install inquirer")
    sys.exit(1)

# --- Variables Globales ---
# On trouve le dossier où est le script
SCRIPTS_DIR = Path(__file__).parent.resolve()
SESSION_PREFIX = "job_"
MY_SCRIPT_NAME = Path(__file__).name

# --- Traductions des Couleurs (pour les messages print) ---
# Note: 'inquirer' gère ses propres couleurs pour le menu.
# Celles-ci sont pour les messages 'print' en dehors du menu.
C_RESET = "\033[0m"
C_ITEM = "\033[38;5;46m"
C_PARAM = "\033[38;5;214m"
C_INFO = "\033[38;5;250m"
C_WARN = "\033[38;5;196m"
C_TITLE = "\033[38;5;81m"

# --- Vérification des Outils ---
def check_tools():
    """Vérifie si tmux est installé."""
    if not shutil.which("tmux"):
        print(f"{C_WARN}ERREUR : tmux n'est pas installé.{C_RESET}")
        print("Veuillez installer tmux pour utiliser ce menu.")
        sys.exit(1)

# -------------------------------------------------------
# Extraction des paramètres argparse d'un script Python
# -------------------------------------------------------
def extract_params(file_path: Path) -> List[str]:
    """
    Utilise une regex pour trouver les 'add_argument' et extraire les flags.
    (ex: '-f', '--foo')
    """
    params = []
    # La regex est une traduction directe de votre grep/sed
    param_regex = re.compile(r"add_argument\(\s*['\"](-{1,2}[a-zA-Z0-9_-]+)")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # Utilise findall pour trouver toutes les correspondances
            matches = param_regex.findall(content)
            # Utilise un set pour dédupliquer, puis trie
            params = sorted(list(set(matches)))
    except Exception:
        # Ignore les erreurs de lecture (ex: permissions, encodage)
        pass
    return params

# -------------------------------------------------------
# Déterminer l’icône d’un script
# -------------------------------------------------------
def icon_for_script(name: str) -> str:
    """Traduction directe de votre logique d'icônes."""
    name = name.lower()
    if any(s in name for s in ["720", "1080", "encode", "fr"]): return "🎬"
    if any(s in name for s in ["audio", "aac", "mp3", "opus", "flac"]): return "🎧"
    if any(s in name for s in ["iso", "bluray", "makemkv", "dvd"]): return "📀"
    if any(s in name for s in ["mobile", "phone", "lite"]): return "📱"
    return "📄"

# -------------------------------------------------------
# Liste des entrées : script + paramètres argparse
# -------------------------------------------------------
def list_entries() -> List[dict]:
    """
    Construit la liste des scripts et de leurs paramètres.
    Retourne une liste de dictionnaires.
    """
    entries = []
    
    # Utilise glob pour trouver les .py et .sh
    script_files = sorted(
        [p for p in SCRIPTS_DIR.glob("*") 
         if (p.suffix == ".py" or p.suffix == ".sh") and p.name != MY_SCRIPT_NAME]
    )

    for path in script_files:
        f = path.name
        icon = icon_for_script(f)

        # Ajoute le script lui-même (sans paramètre)
        entries.append({
            "script": f,
            "param": None,
            "icon": icon,
            "path": path
        })

        # Si c'est un script python, on cherche ses paramètres
        if f.endswith(".py"):
            for param in extract_params(path):
                entries.append({
                    "script": f,
                    "param": param,
                    "icon": icon,
                    "path": path
                })
                
    return entries

# -------------------------------------------------------
# Vérifie si une session tmux existe
# -------------------------------------------------------
def session_exists(session_name: str) -> bool:
    """Vérifie si la session tmux existe déjà."""
    result = subprocess.run(
        ["tmux", "has-session", "-t", session_name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return result.returncode == 0

# -------------------------------------------------------
# Lance un script dans tmux
# -------------------------------------------------------
def start_script(index_menu: int, entry: dict):
    """
    Lance un script dans une nouvelle session tmux et s'y attache.
    Le 'index_menu' est le numéro de choix (1, 2, 3...)
    'entry' est le dictionnaire de l'entrée sélectionnée.
    """
    script = entry["script"]
    param = entry["param"]
    path = entry["path"]
    
    base = Path(script).stem # Enlève l'extension
    suffix = f"_{param.lstrip('-')}" if param else ""
    
    # LOGIQUE MODIFIÉE : Le nom de session est "job_INDEX_BASE_SUFFIXE"
    session = f"{SESSION_PREFIX}{index_menu}_{base}{suffix}"
    
    cmd_list = []

    if script.endswith(".py"):
        cmd_list = ["python3", str(path)]
    else:
        cmd_list = ["bash", str(path)]

    if param:
        cmd_list.append(param)
        
    cmd_str = " ".join(cmd_list) # Pour la création de session

    if not session_exists(session):
        print(f"Création de la session : {C_ITEM}{session}{C_RESET}")
        subprocess.run(
            ["tmux", "new-session", "-d", "-s", session, cmd_str],
            check=True
        )
    else:
        print(f"Attachement à la session existante : {C_ITEM}{session}{C_RESET}")

    # On s'attache à la session.
    # IMPORTANT : subprocess.run bloque le script Python.
    print("... Attachement (Ctrl+b, d pour détacher) ...")
    subprocess.run(["tmux", "attach", "-t", session])

# -------------------------------------------------------
# Récupère les sessions tmux actives
# -------------------------------------------------------
def get_tmux_sessions() -> List[str]:
    """Retourne une liste des noms de sessions tmux actives."""
    try:
        result = subprocess.run(
            ["tmux", "ls", "-F", "#{session_name}"],
            capture_output=True,
            text=True,
            check=True
        )
        sessions = result.stdout.strip().split("\n")
        return [s for s in sessions if s] # Filtre les lignes vides
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []

# -------------------------------------------------------
# Menu des sessions tmux (INTERACTIF)
# -------------------------------------------------------
def list_sessions_menu():
    """Affiche le menu interactif de gestion des sessions tmux."""
    
    while True:
        sessions = get_tmux_sessions()
        
        if not sessions:
            print(f"\n{C_WARN}Aucune session tmux active.{C_RESET}")
            input("Appuyez sur Entrée pour revenir.")
            return

        # On construit les choix pour inquirer
        choices = []
        # Tuples (Texte à afficher, Donnée à retourner)
        for s in sessions:
            choices.append((f"🧲 Attacher → {C_ITEM}{s}{C_RESET}", {"action": "attach", "session": s}))
        
        choices.append(inquirer.Separator()) # Ligne de séparation
        
        for s in sessions:
            choices.append((f"💀 Tuer     → {C_WARN}{s}{C_RESET}", {"action": "kill", "session": s}))
            
        choices.append(inquirer.Separator())
        choices.append((f"{C_INFO}  0) Retour{C_RESET}", {"action": "back"}))

        questions = [
            inquirer.List(
                'choice',
                message=f"{C_TITLE}============== SESSIONS TMUX ACTIVES =============={C_RESET}",
                choices=choices,
                carousel=True # Permet de boucler en haut/bas
            ),
        ]
        
        try:
            # Efface l'écran avant d'afficher le menu
            print("\033c", end="")
            answers = inquirer.prompt(questions, raise_keyboard_interrupt=True)
            choice_data = answers['choice']
            
            action = choice_data["action"]
            
            if action == "back":
                return # Retourne au menu principal
                
            elif action == "attach":
                session = choice_data["session"]
                print(f"Attachement à {C_ITEM}{session}{C_RESET}...")
                subprocess.run(["tmux", "attach", "-t", session])
                # Après détachement, on revient ici. La boucle 'while True'
                # va rafraîchir la liste des sessions.
                
            elif action == "kill":
                session = choice_data["session"]
                print(f"{C_WARN}Suppression de la session {session}...{C_RESET}")
                subprocess.run(["tmux", "kill-session", "-t", session])
                # Reste dans la boucle pour afficher le menu mis à jour
                
        except (KeyboardInterrupt, TypeError):
             # Gère Ctrl+C ou si 'answers' est None (menu vide)
            return

# -------------------------------------------------------
# MENU PRINCIPAL (INTERACTIF)
# -------------------------------------------------------
def main_menu():
    """La boucle principale du menu interactif."""
    
    while True:
        # 1. Remplit le tableau 'entries'
        entries = list_entries()
        
        # 2. Construit la liste des choix pour inquirer
        # On utilise une liste de tuples : (Texte affiché, Valeur retournée)
        
        choices = []
        i = 1
        for entry in entries:
            script = entry["script"]
            param = entry["param"]
            icon = entry["icon"]
            
            # On stocke l'index du menu (1-based) dans l'objet de retour
            entry_data = {"type": "script", "index": i, "data": entry}

            if param:
                # Ligne avec paramètre
                display_text = f"  {i:>2}) {icon}  {C_ITEM}{script:<30}{C_RESET} — {C_PARAM}{param}{C_RESET}"
            else:
                # Ligne sans paramètre
                display_text = f"  {i:>2}) {icon}  {C_ITEM}{script}{C_RESET}"
            
            choices.append((display_text, entry_data))
            i += 1

        # Ajoute les options fixes
        choices.append(inquirer.Separator())
        choices.append((f"  50) 🧰  {C_INFO}Gérer les sessions tmux actives{C_RESET}", {"type": "tmux"}))
        choices.append((f"   0) ❌  {C_WARN}Quitter{C_RESET}", {"type": "quit"}))

        # 3. Crée la question
        questions = [
            inquirer.List(
                'choice',
                message=f"{C_TITLE}============== MENU SCRIPTS =============={C_RESET}",
                choices=choices,
                carousel=True # Permet de boucler
            ),
        ]
        
        try:
            # Efface l'écran avant d'afficher le menu
            print("\033c", end="")
            
            # 4. Affiche le menu et attend la sélection
            answers = inquirer.prompt(questions, raise_keyboard_interrupt=True)
            
            # 5. Gère la sélection
            if not answers:
                # Si l'utilisateur fait Ctrl+C
                raise KeyboardInterrupt
                
            selected_data = answers['choice']
            
            if selected_data["type"] == "script":
                # L'utilisateur a choisi un script
                print("\033c", end="") # Clear
                start_script(selected_data["index"], selected_data["data"])
                # Après le détachement de tmux, la boucle continue
                print("... Retour au menu ...")
            
            elif selected_data["type"] == "tmux":
                # L'utilisateur veut gérer tmux
                list_sessions_menu()
            
            elif selected_data["type"] == "quit":
                print("Au revoir !")
                sys.exit(0)
                
        except KeyboardInterrupt:
            # Gère Ctrl+C proprement
            print("\nAu revoir !")
            sys.exit(0)
        except Exception as e:
            # Gère les erreurs inattendues
            print(f"{C_WARN}Une erreur est survenue : {e}{C_RESET}")
            input("Appuyez sur Entrée pour continuer...")


# --- Lancement ---
if __name__ == "__main__":
    check_tools()
    main_menu()