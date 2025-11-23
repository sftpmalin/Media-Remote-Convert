#!/usr/bin/env bash

# --- Variables Globales ---
# On trouve le dossier où est le script, peu importe d'où on le lance
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_PREFIX="job_"

# --- Couleurs (Conservées) ---
C_RESET="\033[0m"
C_TITLE="\033[38;5;81m"
C_ITEM="\033[38;5;46m"
C_PARAM="\033[38;5;214m"
C_INFO="\033[38;5;250m"
C_WARN="\033[38;5;196m"

# --- Vérification des Outils ---
if ! command -v tmux &> /dev/null; then
    echo -e "${C_WARN}ERREUR : tmux n'est pas installé.${C_RESET}"
    echo "Veuillez installer tmux pour utiliser ce menu."
    exit 1
fi

# -------------------------------------------------------
# Extraction des paramètres argparse d'un script Python
# Amélioré pour être plus robuste (gère les espaces)
# -------------------------------------------------------
extract_params() {
    local file="$1"
    # Utilise grep -oE pour trouver la ligne, et sed -E pour extraire JUSTE le paramètre
    grep -oE "add_argument\(\s*['\"](-{1,2}[a-zA-Z0-9_-]+)" "$file" 2>/dev/null \
        | sed -E "s/add_argument\(\s*['\"]//g" \
        | sort -u
}

# -------------------------------------------------------
# Déterminer l’icône d’un script (Conservé 100%)
# -------------------------------------------------------
icon_for_script() {
    local name="$(echo "$1" | tr '[:upper:]' '[:lower:]')"

    [[ "$name" =~ 720|1080|encode|fr ]] && echo "🎬" && return
    [[ "$name" =~ audio|aac|mp3|opus|flac ]] && echo "🎧" && return
    [[ "$name" =~ iso|bluray|makemkv|dvd ]] && echo "📀" && return
    [[ "$name" =~ mobile|phone|lite ]] && echo "📱" && return

    echo "📄"
}

# -------------------------------------------------------
# Liste des entrées : script + paramètres argparse
# Amélioré pour utiliser 'find' (plus stable que 'ls')
# -------------------------------------------------------
list_entries() {
    # On vide le tableau global
    entries=()

    # On utilise 'find' pour lister les .py et .sh dans le dossier du script
    # -maxdepth 1 : ne cherche pas dans les sous-dossiers
    # sed "s|...||" : enlève le chemin complet pour n'avoir que le nom du fichier
    local script_files
    mapfile -t script_files < <(find "$SCRIPTS_DIR" -maxdepth 1 -type f \( -name "*.py" -o -name "*.sh" \) | sed "s|$SCRIPTS_DIR/||" | sort)

    for f in "${script_files[@]}"; do
        # On s'assure de ne pas s'afficher soi-même
        [[ "$f" == "menu.sh" ]] && continue

        local path="$SCRIPTS_DIR/$f"

        # Ajoute le script lui-même (sans paramètre)
        entries+=("$f|")

        # Si c'est un script python, on cherche ses paramètres
        if [[ "$f" == *.py ]]; then
            while IFS= read -r param; do
                # Ajoute une entrée pour chaque paramètre trouvé
                entries+=("$f|$param")
            done < <(extract_params "$path")
        fi
    done
}

# -------------------------------------------------------
# Vérifie si une session tmux existe (Conservé 100%)
# -------------------------------------------------------
session_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

# -------------------------------------------------------
# Lance un script dans tmux (MODIFIÉ)
# Ajout de $index_menu pour le nom de session unique.
# -------------------------------------------------------
start_script() {
    local index_menu="$1" # NOUVEL ARGUMENT : Le numéro de choix du menu
    local script="$2"
    local param="$3"
    local base="${script%.*}"
    local suffix=""
    [[ -n "$param" ]] && suffix="_${param#-}" # Enlève le '-' du paramètre pour le nom

    # LOGIQUE MODIFIÉE : Le nom de session est maintenant "job_INDEX_BASE_SUFFIXE"
    local session="${SESSION_PREFIX}${index_menu}_${base}${suffix}"
    local cmd=""

    # La logique que vous vouliez : 'python3' ou 'bash'
    if [[ "$script" == *.py ]]; then
        cmd="python3 \"$SCRIPTS_DIR/$script\""
    else
        cmd="bash \"$SCRIPTS_DIR/$script\""
    fi

    # Ajoute le paramètre à la commande s'il existe
    [[ -n "$param" ]] && cmd="$cmd $param"

    if ! session_exists "$session"; then
        echo "Création de la session : ${C_ITEM}$session${C_RESET}"
        tmux new-session -d -s "$session" "$cmd"
    else
        echo "Attachement à la session existante : ${C_ITEM}$session${C_RESET}"
    fi

    # On s'attache à la session
    tmux attach -t "$session"
}

# -------------------------------------------------------
# Menu des sessions tmux (Conservé 100%)
# -------------------------------------------------------
list_sessions() {
    mapfile -t sessions < <(tmux ls 2>/dev/null | cut -d: -f1)

    if [[ ${#sessions[@]} -eq 0 ]]; then
        echo -e "\n${C_WARN}Aucune session tmux active.${C_RESET}"
        read -p "Appuyez sur Entrée pour revenir."
        return
    fi

    while true; do
        clear
        echo -e "${C_TITLE}============== SESSIONS TMUX ACTIVES ==============${C_RESET}\n"

        local n="${#sessions[@]}"

        # Options pour "Attacher"
        for ((i=0; i<n; i++)); do
            echo -e "  $((i+1))) 🧲 Attacher → ${C_ITEM}${sessions[$i]}${C_RESET}"
        done

        echo ""
        # Options pour "Tuer"
        for ((i=0; i<n; i++)); do
            echo -e "  $((i+1+n))) 💀 Tuer     → ${C_WARN}${sessions[$i]}${C_RESET}"
        done

        echo -e "\n${C_INFO}  0) Retour${C_RESET}"
        echo -e "\n- - - - - - - - - - - - - - - - - - - - -"
        read -rp "Choix : " choice

        [[ "$choice" == "0" ]] && return

        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            # Gère "Attacher"
            if (( choice>=1 && choice<=n )); then
                tmux attach -t "${sessions[$((choice-1))]}"
                return # Quitte list_sessions et tmux s'occupe du reste

            # Gère "Tuer"
            elif (( choice>n && choice<=2*n )); then
                local idx=$((choice-n-1))
                tmux kill-session -t "${sessions[$idx]}"
                echo -e "\n${C_WARN}Session ${sessions[$idx]} supprimée.${C_RESET}"
                read -p "Appuyez sur Entrée..."
                return # Retourne au menu principal
            fi
        fi
        
        # Si choix invalide, la boucle recommence
        echo -e "\n${C_WARN}Choix non valide.${C_RESET}"
        sleep 1
    done
}

# -------------------------------------------------------
# MENU PRINCIPAL (MODIFIÉ)
# Ajout de l'index dans l'appel à start_script.
# -------------------------------------------------------
main_menu() {
    while true; do
        clear
        echo -e "${C_TITLE}============== MENU SCRIPTS ==============${C_RESET}\n"

        # Remplit le tableau 'entries'
        list_entries

        # Affiche toutes les entrées
        local i=1
        for entry in "${entries[@]}"; do
            script="${entry%%|*}"
            param="${entry#*|}"
            icon="$(icon_for_script "$script")"

            if [[ -n "$param" ]]; then
                # Ligne avec paramètre
                echo -e "  ${i}) $icon  ${C_ITEM}${script}${C_RESET}  — ${C_PARAM}${param}${C_RESET}"
            else
                # Ligne sans paramètre (script simple)
                echo -e "  ${i}) $icon  ${C_ITEM}${script}${C_RESET}"
            fi
            ((i++))
        done

        # Affiche les options fixes
        echo -e "\n  50) 🧰  ${C_INFO}Gérer les sessions tmux actives${C_RESET}"
        echo -e "  0) ❌  ${C_WARN}Quitter${C_RESET}"
        
        echo -e "\n- - - - - - - - - - - - - - - - - - - - -"
        read -rp "Choix : " choice

        case "$choice" in
            0)
                echo "Au revoir !"
                exit 0
                ;;
            50)
                list_sessions
                ;;
            *)
                # Gère le lancement de script
                if [[ "$choice" =~ ^[0-9]+$ ]]; then
                    local index=$((choice-1))
                    # Vérifie si l'index est valide
                    if (( index>=0 && index<${#entries[@]} )); then
                        script="${entries[$index]%%|*}"
                        param="${entries[$index]#*|}"
                        
                        # Si param est vide, la séparation '|' le met égal au script, on le vide
                        [[ "$param" == "$script" ]] && param=""
                        
                        # APPEL MODIFIÉ : on passe le choix ($choice) comme premier argument
                        start_script "$choice" "$script" "$param"
                        # Après l'attachement, l'utilisateur revient ici. On force un 'clear'
                        echo "Retour au menu..."
                        sleep 1
                    else
                        echo -e "\n${C_WARN}Choix non valide.${C_RESET}"
                        sleep 1
                    fi
                else
                    echo -e "\n${C_WARN}Choix non valide.${C_RESET}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# --- Lancement ---
# On déclare le tableau 'entries' comme global
declare -a entries
# On lance le menu
main_menu
