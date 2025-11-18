#!/bin/bash
set -e

# [MODIF PRO] Gestion de la variable d'environnement USERS_VAR
USERS_VAR="${USERS_VAR:-}" # S'assure que la variable est vide si non définie
USERS_CONF_FILE="/data/config/users.conf"

# Variables pour les chemins des modèles
USER_SKEL_DIR="/usr/local/share/user_skel"

# --- 1. Initialisation du volume /data (si vide) ---
# On vérifie le dossier config plutôt que le fichier users.conf pour l'init générale
if [ ! -d "/data/config" ]; then
    echo "--- Première exécution détectée : Initialisation de /data ---"
    
    # [MODIFICATION] Création de toute l'arborescence (y compris /data/home)
    mkdir -p /data/config /data/keys /data/userkeys /data/private_keys /data/bin /data/home 

    echo "Copie des binaires ffmpeg par défaut..."
    cp /usr/local/bin/ffmpeg_defaults/* /data/bin/

    # NOTE : La création de users.conf par défaut est déplacée plus bas (Logique Rétrocompatible)

    echo "Création de /data/config/sshd_config sécurisé..."
    cat <<EOT > /data/config/sshd_config
Port 22
Protocol 2
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitEmptyPasswords no
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
AllowTcpForwarding yes
X11Forwarding yes
HostKey /data/keys/ssh_host_rsa_key
HostKey /data/keys/ssh_host_ecdsa_key
HostKey /data/keys/ssh_host_ed25519_key
EOT
else
    echo "--- Volume /data/config déjà initialisé. ---"
fi

# --- [NOUVEAU] LOGIQUE DE RÉTROCOMPATIBILITÉ USERS_VAR ---
if [ -n "$USERS_VAR" ]; then
    # CAS 1: USERS_VAR est définie (Prioritaire)
    echo "--- Traitement de USERS_VAR (Prioritaire) ---"
    echo "# Format: user:pass:UID:GID" > "$USERS_CONF_FILE"
    echo "$USERS_VAR" >> "$USERS_CONF_FILE"
    echo "Fichier $USERS_CONF_FILE mis à jour depuis USERS_VAR."

else
    # CAS 2: USERS_VAR est VIDE
    echo "--- USERS_VAR non définie. Vérification du fichier users.conf existant... ---"
    
    if [ ! -f "$USERS_CONF_FILE" ]; then
        # CAS 2a: Le fichier n'existe pas (Nouvelle installation)
        echo "ATTENTION : Nouvelle installation et USERS_VAR non définie."
        echo "Création d'un fichier $USERS_CONF_FILE par défaut."
        cat <<EOT > "$USERS_CONF_FILE"
# Format: user:pass:UID:GID
user1:ignored:1000:100
user2:ignored:1001:100
EOT
    else
        # CAS 2b: Le fichier EXISTE (Mode de compatibilité)
        echo "Utilisation du fichier $USERS_CONF_FILE existant (Mode de compatibilité)."
    fi
fi
# --- [FIN LOGIQUE RÉTROCOMPATIBILITÉ] ---

# Force l'exécution des binaires FFmpeg (Important pour ce container)
echo "Application des permissions d'exécution sur /data/bin..."
chmod +x /data/bin/*


# --- 2. Génération/Liaison des clés d'hôte SSH ---
echo "Configuration du serveur SSH..."
if [ ! -f "/data/keys/ssh_host_rsa_key" ]; then
    echo "Génération des clés d'hôte SSH persistantes..."
    ssh-keygen -t rsa -b 4096 -f /data/keys/ssh_host_rsa_key -N ""
    ssh-keygen -t ecdsa -f /data/keys/ssh_host_ecdsa_key -N ""
    ssh-keygen -t ed25519 -f /data/keys/ssh_host_ed25519_key -N ""
fi
chmod 600 /data/keys/*_key
chmod 644 /data/keys/*.pub
rm -f /etc/ssh/ssh_host_*
ln -s /data/keys/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key
ln -s /data/keys/ssh_host_rsa_key.pub /etc/ssh/ssh_host_rsa_key.pub
ln -s /data/keys/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key
ln -s /data/keys/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub
ln -s /data/keys/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
ln -s /data/keys/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key.pub
ln -sf /data/config/sshd_config /etc/ssh/sshd_config

# --- 2b. Vérification de l'utilisateur de service 'main' ---
echo "Vérification de l'utilisateur de service 'main' (9000:100)..."
if ! id "main" >/dev/null 2>&1; then
    echo "  -> 'main' non trouvé. Recréation..."
    groupadd -g 100 users || true
    useradd -N -s /bin/bash -u 9000 -g 100 main
else
    echo "  -> 'main' existe."
fi

# --- 3. Synchronisation des utilisateurs ---
echo "Synchronisation des utilisateurs..."
MIN_UID=1000

# --- Étape 3a: Suppression des utilisateurs orphelins ---
# On lit le fichier users.conf qui a été généré ou validé plus haut
VALID_USERS=$(grep -vE "^#|^$" "$USERS_CONF_FILE" | cut -d: -f1 | xargs)
echo "Utilisateurs valides dans users.conf: $VALID_USERS"

MANAGED_USERS=$(awk -F: -v min_uid="$MIN_UID" '$3 >= min_uid && $1 != "main" { print $1 }' /etc/passwd | xargs)
echo "Utilisateurs gérés (excl. main) trouvés dans le conteneur: $MANAGED_USERS"

for user in $MANAGED_USERS; do
    if ! echo "$VALID_USERS" | grep -qw "$user"; then
        echo "--- Suppression de l'utilisateur orphelin: $user ---"
        deluser "$user"
    fi
done

# --- Étape 3b: Création/Mise à jour des utilisateurs ---
echo "Traitement des utilisateurs depuis $USERS_CONF_FILE..."

tail -n +2 "$USERS_CONF_FILE" | while IFS=: read -r TARGET_USER TARGET_PASS TARGET_PUID TARGET_PGID || [ -n "$TARGET_USER" ]; do
    
    if [ -z "$TARGET_USER" ] || [[ "$TARGET_USER" = \#* ]]; then
        continue
    fi

    echo "--- Traitement de: $TARGET_USER (UID: $TARGET_PUID, GID: $TARGET_PGID) ---"

    # ICI: On garde /data/home comme demandé dans votre version
    TARGET_HOME_DIR="/data/home/$TARGET_USER"
    TARGET_SCRIPTS_DIR="$TARGET_HOME_DIR/scripts"

    if ! getent group "$TARGET_PGID" >/dev/null; then
        echo "Création du groupe (GID: $TARGET_PGID)..."
        addgroup --gid "$TARGET_PGID" "group-$TARGET_PGID"
    fi

    if ! getent passwd "$TARGET_PUID" >/dev/null; then
        echo "Création de l'utilisateur $TARGET_USER..."
        adduser --disabled-password --gecos "" \
            --uid "$TARGET_PUID" --gid "$TARGET_PGID" \
            --home "$TARGET_HOME_DIR" \
            --shell "/bin/bash" "$TARGET_USER"
    fi
    
    echo "Vérification de l'arborescence pour $TARGET_USER..."
    mkdir -p "$TARGET_HOME_DIR/.ssh"
    mkdir -p "$TARGET_SCRIPTS_DIR"
    touch "$TARGET_HOME_DIR/.profile"

    # --- LOGIQUE CLÉS SSH (INCHANGÉE) ---
    
    PUB_KEY_FILE="/data/userkeys/$TARGET_USER.pub"
    PRIVATE_KEY_FILE_PATH="/data/private_keys/${TARGET_USER}_ssh_key"
    
    if [ ! -f "$PUB_KEY_FILE" ]; then
        echo "--- (Étape 4) Clé publique non trouvée pour $TARGET_USER. Génération... ---"
        ssh-keygen -t ed25519 -f "$PRIVATE_KEY_FILE_PATH" -N ""
        echo "Clé privée générée dans: $PRIVATE_KEY_FILE_PATH"
        mv "${PRIVATE_KEY_FILE_PATH}.pub" "$PUB_KEY_FILE"
        chmod 600 "$PRIVATE_KEY_FILE_PATH"
        echo "Clé publique déplacée vers: $PUB_KEY_FILE"
    else
        echo "--- (Étape 3) Clé publique $PUB_KEY_FILE déjà présente. ---"
    fi

    if [ -f "$PUB_KEY_FILE" ]; then
        echo "--- (Étape 5) Installation de la clé publique dans authorized_keys pour $TARGET_USER... ---"
        cat "$PUB_KEY_FILE" | dos2unix > "$TARGET_HOME_DIR/.ssh/authorized_keys"
    else
        echo "--- (Étape 5) ATTENTION: Clé publique $PUB_KEY_FILE non trouvée, authorized_keys sera vide. ---"
        rm -f "$TARGET_HOME_DIR/.ssh/authorized_keys"
    fi
    # --- [FIN LOGIQUE CLÉS] ---


    # --- COPIE SQUELETTE (FFmpeg Scripts) ---
    echo "  -> Copie des fichiers de squelette utilisateur..."
    
    # Fichiers de script (dans /scripts)
    if [ -f "$USER_SKEL_DIR/menu.sh" ]; then
        cp "$USER_SKEL_DIR/menu.sh" "$TARGET_SCRIPTS_DIR/menu.sh"
        chmod +x "$TARGET_SCRIPTS_DIR/menu.sh"
    fi

    # Fichiers de lancement (à la racine du home)
    if [ -f "$USER_SKEL_DIR/lautch_menu.bat" ]; then
        cp "$USER_SKEL_DIR/lautch_menu.bat" "$TARGET_HOME_DIR/lautch_menu.bat"
    fi
    if [ -f "$USER_SKEL_DIR/lautch_menu.sh" ]; then
        cp "$USER_SKEL_DIR/lautch_menu.sh" "$TARGET_HOME_DIR/lautch_menu.sh"
        chmod +x "$TARGET_HOME_DIR/lautch_menu.sh"
    fi
    
    # Force le umask
    if ! grep -q "umask 022" "$TARGET_HOME_DIR/.profile"; then
        echo "umask 022" >> "$TARGET_HOME_DIR/.profile"
    fi
    
    # Force le PATH (Avec /data/bin pour FFmpeg)
    PATH_STRING='export PATH="/data/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"'
    if ! grep -q "$PATH_STRING" "$TARGET_HOME_DIR/.profile"; then
        echo "Ajout de /data/bin au PATH de $TARGET_USER"
        echo "$PATH_STRING" >> "$TARGET_HOME_DIR/.profile"
    fi

    echo "Application des permissions pour $TARGET_HOME_DIR..."
    
    chown -R "$TARGET_PUID":"$TARGET_PGID" "$TARGET_HOME_DIR"
    chmod 700 "$TARGET_HOME_DIR"
    chmod 700 "$TARGET_HOME_DIR/.ssh"
    [ -f "$TARGET_HOME_DIR/.ssh/authorized_keys" ] && chmod 600 "$TARGET_HOME_DIR/.ssh/authorized_keys"
    
    echo "Application des ACL sur $TARGET_SCRIPTS_DIR pour l'auto-exécution..."
    setfacl -d -m u::rwx,g::rx,o::rx "$TARGET_SCRIPTS_DIR"
    setfacl -m u::rwx,g::rx,o::rx "$TARGET_SCRIPTS_DIR"

done

# --- 4. COHÉRENCE AVEC LE DOCKER FLASK ---
echo "Assurance de la propriété du dossier /data/config à l'UID 9000 (main)..."
chown -R 9000:100 /data/config

# --- 5. Lancement du service ---
echo "--- (Étape 6) Démarrage du serveur SSH (en tant que root) ---"
exec "$@"