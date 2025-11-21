#!/bin/bash
set -e

# --- 1. CONFIGURATION SSH ---
SSH_PERMIT_ROOT="${SSH_PERMIT_ROOT:-no}"
SSH_PUBKEY_AUTH="${SSH_PUBKEY_AUTH:-yes}"
SSH_PASS_AUTH="${SSH_PASS_AUTH:-no}"
SSH_CHALLENGE_AUTH="${SSH_CHALLENGE_AUTH:-no}"
SSH_EMPTY_PASS="${SSH_EMPTY_PASS:-no}"
SSH_USE_PAM="${SSH_USE_PAM:-yes}"
SSH_TCP_FORWARD="${SSH_TCP_FORWARD:-yes}"
SSH_X11_FORWARD="${SSH_X11_FORWARD:-yes}"

USERS_CONF_FILE="/data/config/users.conf"
USER_SKEL_DIR="/usr/local/share/user_skel"

# --- 2. INITIALISATION /DATA ---
if [ ! -d "/data/config" ]; then
    echo "--- Première exécution : Initialisation ---"
    mkdir -p /data/config /data/keys /data/userkeys /data/private_keys /data/bin /data/home

    echo "Copie des binaires ffmpeg par défaut..."
    # On vérifie si le dossier source existe pour éviter une erreur si l'image est différente
    if [ -d "/usr/local/bin/ffmpeg_defaults" ]; then
        cp -n /usr/local/bin/ffmpeg_defaults/* /data/bin/ || true
    fi

    echo "Génération du sshd_config..."
    cat <<EOT > /data/config/sshd_config
Port 22
Protocol 2
PermitRootLogin $SSH_PERMIT_ROOT
PubkeyAuthentication $SSH_PUBKEY_AUTH
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication $SSH_PASS_AUTH
ChallengeResponseAuthentication $SSH_CHALLENGE_AUTH
PermitEmptyPasswords $SSH_EMPTY_PASS
UsePAM $SSH_USE_PAM
Subsystem sftp /usr/lib/openssh/sftp-server
AllowTcpForwarding $SSH_TCP_FORWARD
X11Forwarding $SSH_X11_FORWARD
HostKey /data/keys/ssh_host_rsa_key
HostKey /data/keys/ssh_host_ecdsa_key
HostKey /data/keys/ssh_host_ed25519_key
EOT
fi

# --- 3. TRAITEMENT UTILISATEURS (BOUCLE USERS_VAR) ---
echo "--- Mise à jour users.conf ---"
echo "# Format: user:pass:UID:GID" > "$USERS_CONF_FILE"

FOUND_USERS=false
# Cette boucle récupère toutes les variables USERS_VAR1, USERS_VAR2, etc.
for VAR_NAME in $(env | grep -E '^USERS_VAR[0-9]+=' | sort -V); do
    USER_LINE="${VAR_NAME#*=}"
    if [ -n "$USER_LINE" ]; then
        echo "Ajout depuis variable : $USER_LINE"
        echo "$USER_LINE" >> "$USERS_CONF_FILE"
        FOUND_USERS=true
    fi
done

if ! $FOUND_USERS; then
    if [ $(wc -l < "$USERS_CONF_FILE") -le 1 ]; then 
        echo "--- Aucune variable trouvée, création user par défaut ---"
        cat <<EOT >> "$USERS_CONF_FILE"
user1:ignored:1000:100
user2:ignored:1001:100
EOT
    fi
fi

# Force l'exécution des binaires FFmpeg
chmod +x /data/bin/* || true

# --- 4. CLÉS SERVEUR ---
if [ ! -f "/data/keys/ssh_host_rsa_key" ]; then
    echo "Génération clés serveur..."
    ssh-keygen -t rsa -b 4096 -f /data/keys/ssh_host_rsa_key -N ""
    ssh-keygen -t ecdsa -f /data/keys/ssh_host_ecdsa_key -N ""
    ssh-keygen -t ed25519 -f /data/keys/ssh_host_ed25519_key -N ""
fi
chmod 600 /data/keys/*_key || true
chmod 644 /data/keys/*.pub || true

rm -f /etc/ssh/ssh_host_*
ln -s /data/keys/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key
ln -s /data/keys/ssh_host_rsa_key.pub /etc/ssh/ssh_host_rsa_key.pub
ln -s /data/keys/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key
ln -s /data/keys/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub
ln -s /data/keys/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
ln -s /data/keys/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key.pub
ln -sf /data/config/sshd_config /etc/ssh/sshd_config

# --- 5. UTILISATEUR MAIN ---
if ! id "main" >/dev/null 2>&1; then
    groupadd -g 100 users || true
    useradd -N -s /bin/bash -u 9000 -g 100 main || true
    echo "main:unusable_pass_$(date +%s)" | chpasswd
fi

# --- 6. SYNCHRO UTILISATEURS ---
echo "Synchronisation..."
MIN_UID=1000

# A. Nettoyage
VALID_USERS=$(grep -vE "^#|^$" "$USERS_CONF_FILE" | cut -d: -f1 | xargs)
MANAGED_USERS=$(awk -F: -v min_uid="$MIN_UID" '$3 >= min_uid && $1 != "main" { print $1 }' /etc/passwd | xargs)
for user in $MANAGED_USERS; do
    if ! echo "$VALID_USERS" | grep -qw "$user"; then
        echo "Suppression: $user"
        deluser "$user"
    fi
done

# B. Création / Mise à jour (Boucle FD3 sécurisée)
while IFS=: read -u 3 -r TARGET_USER TARGET_PASS TARGET_PUID TARGET_PGID || [ -n "$TARGET_USER" ]; do
    
    if [ -z "$TARGET_USER" ] || [[ "$TARGET_USER" = \#* ]]; then continue; fi

    echo "Traitement : $TARGET_USER"
    
    # Home interne pour FFmpeg
    TARGET_HOME_DIR="/data/home/$TARGET_USER"
    TARGET_SCRIPTS_DIR="$TARGET_HOME_DIR/scripts"

    if ! getent group "$TARGET_PGID" >/dev/null; then addgroup --gid "$TARGET_PGID" "group-$TARGET_PGID" || true; fi
    
    if ! getent passwd "$TARGET_PUID" >/dev/null; then
        adduser --disabled-password --gecos "" \
            --uid "$TARGET_PUID" --gid "$TARGET_PGID" \
            --home "$TARGET_HOME_DIR" \
            --shell "/bin/bash" "$TARGET_USER" || true
            
        echo "$TARGET_USER:unusable_pass_$(date +%s)_$RANDOM" | chpasswd
    fi
    
    mkdir -p "$TARGET_HOME_DIR/.ssh"
    mkdir -p "$TARGET_SCRIPTS_DIR"
    touch "$TARGET_HOME_DIR/.profile"

    # --- CLÉS DYNAMIQUES ---
    PUB_KEY_FILE="/data/userkeys/$TARGET_USER.pub"
    PRIVATE_KEY_FILE_PATH="/data/private_keys/${TARGET_USER}_ssh_key"
    KEY_VAR="${KEY_VAR:-3072}"

    if [ ! -f "$PUB_KEY_FILE" ]; then
        echo "-> Génération clé ($KEY_VAR)..."
        case "$KEY_VAR" in
            2048)       ssh-keygen -t rsa -b 2048 -f "$PRIVATE_KEY_FILE_PATH" -N "" < /dev/null ;;
            4096)       ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_FILE_PATH" -N "" < /dev/null ;;
            [Ee]d25519) ssh-keygen -t ed25519 -f "$PRIVATE_KEY_FILE_PATH" -N "" < /dev/null ;;
            *)          ssh-keygen -t rsa -b 3072 -f "$PRIVATE_KEY_FILE_PATH" -N "" < /dev/null ;;
        esac
        mv "${PRIVATE_KEY_FILE_PATH}.pub" "$PUB_KEY_FILE"
        chmod 600 "$PRIVATE_KEY_FILE_PATH"
    fi

    if [ -f "$PUB_KEY_FILE" ]; then
        cat "$PUB_KEY_FILE" | dos2unix > "$TARGET_HOME_DIR/.ssh/authorized_keys"
    else
        rm -f "$TARGET_HOME_DIR/.ssh/authorized_keys"
    fi
    # --- FIN CLÉS ---

    # Copie scripts squelette
    if [ -f "$USER_SKEL_DIR/menu.sh" ]; then cp "$USER_SKEL_DIR/menu.sh" "$TARGET_SCRIPTS_DIR/menu.sh"; chmod +x "$TARGET_SCRIPTS_DIR/menu.sh"; fi
    if [ -f "$USER_SKEL_DIR/lautch_menu.bat" ]; then cp "$USER_SKEL_DIR/lautch_menu.bat" "$TARGET_HOME_DIR/lautch_menu.bat"; fi
    if [ -f "$USER_SKEL_DIR/lautch_menu.sh" ]; then cp "$USER_SKEL_DIR/lautch_menu.sh" "$TARGET_HOME_DIR/lautch_menu.sh"; chmod +x "$TARGET_HOME_DIR/lautch_menu.sh"; fi
    
    # Nettoyage
    if ! grep -q "umask 022" "$TARGET_HOME_DIR/.profile"; then echo "umask 022" >> "$TARGET_HOME_DIR/.profile"; fi
    
    # [PATH FFMPEG] Ajout de /data/bin
    PATH_STRING='export PATH="/data/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"'
    if ! grep -q "$PATH_STRING" "$TARGET_HOME_DIR/.profile"; then echo "$PATH_STRING" >> "$TARGET_HOME_DIR/.profile"; fi

    # Permissions (Ici on garde ton système d'origine car c'est interne)
    chown -R "$TARGET_PUID":"$TARGET_PGID" "$TARGET_HOME_DIR" || true
    chmod 700 "$TARGET_HOME_DIR" || true
    chmod 700 "$TARGET_HOME_DIR/.ssh" || true
    [ -f "$TARGET_HOME_DIR/.ssh/authorized_keys" ] && chmod 600 "$TARGET_HOME_DIR/.ssh/authorized_keys" || true
    
    # ACLs pour les scripts (Si setfacl est installé dans l'image)
    if command -v setfacl >/dev/null; then
        setfacl -d -m u::rwx,g::rx,o::rx "$TARGET_SCRIPTS_DIR" || true
        setfacl -m u::rwx,g::rx,o::rx "$TARGET_SCRIPTS_DIR" || true
    fi

done 3< <(tail -n +2 "$USERS_CONF_FILE")

# --- 7. SÉCURITÉ CONFIG ---
echo "Application droits stricts (600)..."
chown -R 9000:100 /data/config || true
chmod 600 /data/config/sshd_config || true
chmod 600 /data/config/users.conf || true

# --- 8. RUN ---
mkdir -p -m 0755 /run/sshd
echo "Démarrage SSH..."
exec "$@"