# Media-Remote-Convert
Serveur SFTP/SSH moderne avec gestion automatique des utilisateurs, clés SSH et FFmpeg.

# 🚀 FFmpeg-SSH Server — SFTP/SSH moderne avec gestion auto + FFmpeg + GPU

Image Docker basée sur **Debian 12**, combinant un serveur **SSH/SFTP sécurisé**, une gestion automatique des utilisateurs, et **FFmpeg** pré-intégré. Compatible Synology, QNAP, Unraid, Debian et Ubuntu. Support natif **Intel VAAPI** et **NVIDIA GPU**. Image légère, stable et autonome, avec stockage entièrement persistant dans `/data`.

## ✨ Fonctionnalités
- 🔐 Authentification 100% par clé SSH (sécurisé, aucun mot de passe)
- 👥 Création automatique des utilisateurs via `USERS_VAR` ou `/data/config/users.conf`
- 🔑 Génération automatique des clés SSH (hôte + utilisateurs)
- 🗂 Isolation complète de chaque utilisateur : `/data/home/<user>`
- 🎥 FFmpeg / FFprobe / FFplay intégrés (statiques)
- 🧩 Scripts utilisateur auto-copiés (`menu.sh`, launchers Windows/Linux)
- 🎛 Support GPU : Intel VAAPI (`/dev/dri`), NVIDIA (méthode moderne `deploy.resources`)
- 📦 Arborescence persistante : `/data/bin`, `/data/config`, `/data/keys`, `/data/home`, etc.

## 📁 Structure du volume `/data`
```
/data
├── bin/               # FFmpeg + scripts
├── config/
│   ├── sshd_config
│   └── users.conf
├── keys/              # Clés d’hôte SSH
├── userkeys/          # Clés publiques utilisateurs
├── private_keys/      # Clés privées générées
└── home/<user>/       # Homes isolés
```

## 🚀 Démarrage rapide (docker run)
```bash
docker run -d \
  --name ffmpeg-ssh \
  --restart unless-stopped \
  -p 2222:22 \
  -v /mnt/sftp-data:/data \
  -e USERS_VAR="user1:ignored:1000:100 \
user2:ignored:1001:100" \
  sftpmalin/ffmpeg:latest
```

## 🧩 Exemple docker-compose
```yaml
version: '3.8'
services:
  ffmpeg-ssh:
    image: sftpmalin/ffmpeg:latest
    container_name: ffmpeg-server
    restart: unless-stopped
    ports:
      - "2222:22"
    devices:
      - "/dev/dri:/dev/dri"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    volumes:
      - ./data-ffmpeg:/data:rw
```

## 👥 Gestion des utilisateurs
### Méthode 1 : via variable USERS_VAR
Format multi-ligne **sans point-virgule** :
```bash
-e USERS_VAR="user1:ignored:1000:100 \
user2:ignored:1001:100"
```

### Méthode 2 : via `/data/config/users.conf`
Créé automatiquement si absent :
```
user1:ignored:1000:100
user2:ignored:1001:100
```

## 🔐 Authentification
- Authentification par clé SSH uniquement  
- Clés d’hôte et clés utilisateur générées automatiquement  
- `authorized_keys` installé automatiquement dans chaque `/data/home/<user>/.ssh/`  

## 🎥 FFmpeg intégré
Accessible immédiatement pour tous les utilisateurs via :
```
/data/bin/ffmpeg
/data/bin/ffprobe
/data/bin/ffplay
```

## 🔗 Code source
GitHub : https://github.com/sftpmalin/Media-Remote-Convert

## 📝 Licence
MIT
