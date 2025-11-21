<p align="center">
  <img src="https://raw.githubusercontent.com/sftpmalin/Media-Remote-Convert/main/logo/sftpmalin1.png" width="200">
</p>

# 📦 Notes de mise à jour – FFmpeg Malin

donc j ai fait comme les 2 autre docker des metre les users 
donc c est toujours la meme chose :

-e USERS_VAR1="user1:pass:uid:gid" \

voila un exemple de commande docker un :

```bash
docker run -d \
  --name FFmpeg \
  --hostname FFmpeg \
  --restart=unless-stopped \
  --net='br0' \
  --ip='192.168.1.27' \
  -p 2222:22 \
  -v /mnt/user/appdata/ffmpeg:/data:rw \
  -e SSH_PASS_AUTH="no" \
  -e SSH_PERMIT_ROOT="no" \
  -e SSH_CHALLENGE_AUTH="no" \
  -e SSH_EMPTY_PASS="no" \
  -e SSH_USE_PAM="yes" \
  -e SSH_TCP_FORWARD="yes" \
  -e SSH_X11_FORWARD="yes" \
  -e SSH_PUBKEY_AUTH="yes" \
  -e KEY_VAR="3072" \
  -e USERS_VAR1="user1:0000:1000:100" \
  -e USERS_VAR2="user2:0000:1001:100" \
  -e USERS_VAR3="user3:0000:1002:100" \
  -e USERS_VAR4="user4:0000:1003:100" \
  -e USERS_VAR5="user5:0000:1004:100" \
  -e USERS_VAR6="user6:0000:1005:100" \
  --runtime=nvidia \
  --gpus all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
  --device /dev/dri:/dev/dri \
sftpmalin/ffmpeg:latest
```


# 🚀 FFmpeg Malin – Édition Yoan
Environnement FFmpeg complet + SSH/SFTP + gestion automatique des utilisateurs, compatible GPUs Intel & NVIDIA  
Plateformes supportées : **amd64** et **arm64**

---

# 📘 Présentation

**FFmpeg Malin – Édition Yoan** est un conteneur Docker moderne, puissant et entièrement autonome pour l’encodage vidéo.  
Il intègre :

- Serveur **SSH/SFTP** minimaliste  
- Gestion **automatique des utilisateurs** via `USERS_VAR` ou `users.conf`  
- Génération **automatique** des clés SSH (hôte + utilisateurs)  
- FFmpeg **Latest Auto-Build** (ffmpeg, ffprobe, ffplay)  
- Support GPU : **NVIDIA NVENC** + **Intel VAAPI**  
- Système d’arborescence unifié dans `/data`  
- Un **menu minimal** pour vos scripts personnalisés  
- Une **stabilité parfaite** (Debian 12)  

Ce conteneur NE fournit PAS de presets FFmpeg.  
👉 Parce que **l’encodage est personnel**. Vous encodez comme vous voulez.

---

# 🆕 Gestion automatique des utilisateurs (USERS_VAR)

Le conteneur peut créer automatiquement tous vos utilisateurs, leurs homes, leurs clés et leurs scripts :

```bash
-e USERS_VAR="user1:0000:1000:100 \
user2:0000:1001:100"
```

✔ une ligne par user  
✔ **pas d’espace** après le `\`  
✔ format : `username:password:uid:gid`  

> Le champ `password` peut être ignoré par le conteneur pour l’authentification SSH (clés uniquement),  
> mais il doit être présent dans le format : `user:pass:uid:gid`.

Pour chaque utilisateur, il génère automatiquement :

```
/data/home/USER/
  ├── launchmenu.bat
  ├── launchmenu.sh
  ├── .ssh/authorized_keys
  └── script/menu.sh

/data/private_keys/USER
/data/userkeys/USER.pub
```

---

# 🧱 Architecture interne

Le conteneur repose sur un volume unique :

```
/data
```

Structure générée :

```
/data
├── bin/               # FFmpeg + scripts
├── config/
│   ├── sshd_config
│   └── users.conf
├── keys/              # Clés SSH de l’hôte
├── userkeys/          # Clés publiques
├── private_keys/      # Clés privées
└── home/
    └── <user>/        # Home complet de chaque utilisateur
```

---

# 🛠 Paquets inclus (Dockerfile)

Le conteneur inclut :

### 🐍 Python et outils
- python3
- python3-pip
- inquirer (menus interactifs)

### 🧰 Outils système
- bash
- tmux
- procps
- dos2unix
- curl / wget
- git
- acl

### 🔐 SSH / SFTP
- openssh-server
- gestion auto des clés hôte + users  
- `authorized_keys` auto

### 🎛 Intel VAAPI
- libva2
- libva-drm2
- intel-media-va-driver

### 🔍 Détection hardware
- pciutils
- usbutils

### 🎬 FFmpeg statique intégré
Copié dans :
```
/usr/local/bin/ffmpeg_defaults/
→ /data/bin/
```

---

# 🎛 Support GPU

## 🟦 NVIDIA NVENC
Ajouter :
```bash
--runtime=nvidia
--gpus all
-e NVIDIA_VISIBLE_DEVICES=all
-e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
```

## 🟩 Intel VAAPI
Ajouter :
```bash
--device /dev/dri:/dev/dri
```

## 🟪 NVIDIA + INTEL en même temps : OK

---

# 🚀 Exemple Docker Run simple

```bash
docker run -d --name ffmpeg \
  --restart unless-stopped \
  -p 2222:22 \
  -v /mnt/user/appdata/ffmpeg:/data \
  -e USERS_VAR="user1:0000:1000:100 \
user2:0000:1001:100" \
  sftpmalin/ffmpeg:latest
```

---

# 🚀 Exemple Docker Run complet (GPU NVIDIA + INTEL)

```bash
docker run -d --name ffmpeg \
  --restart unless-stopped \
  --net='br0' \
  --ip='192.168.1.25' \
  -e TZ="Europe/Paris" \
  -p 2222:22 \
  -v /mnt/user/appdata/ffmpeg:/data \
  -e USERS_VAR="yoan:0000:1000:100 \
invite:0000:1001:100" \
  --runtime=nvidia \
  --gpus all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
  --device /dev/dri:/dev/dri \
  sftpmalin/ffmpeg:latest
```

---

# 🧩 Exemple docker-compose

```yaml
version: '3.8'
services:
  ffmpeg-server:
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
      - ./data-ffmpeg:/data
```

---

# 👤 Déclaration des utilisateurs via fichier

Dans :

```text
/data/config/users.conf
```

Format :

```text
username:password:uid:gid
```

Exemple :

```text
yoan:ignored:1000:100
invite:ignored:1001:100
encodeur:ignored:1002:100
```

> Le champ `password` peut être mis à `ignored`, `0000` ou autre valeur neutre si vous utilisez uniquement les clés SSH.

---

# 🔑 Gestion des clés SSH

Généré automatiquement :

```text
/data/private_keys/<user>
/data/userkeys/<user>.pub
```

Installé automatiquement dans :

```text
/data/home/<user>/.ssh/authorized_keys
```

✔ Clés persistantes  
✔ Possibilité de distribuer la clé privée puis la supprimer côté serveur  

---

# 🧠 Philosophie FFmpeg Malin

FFmpeg Malin ne fournit **aucun preset**, car chacun encode différemment :

- CRF 18 ou 23  
- x264 / x265 / NVENC / AV1  
- filtres personnalisés  
- crop / scaling  
- audio copy ou réencodage  
- 8 bits / 10 bits  

Le conteneur fournit :

✔ FFmpeg complet  
✔ Menu minimal  
✔ Scripts de base  
✔ Environnement propre  

Ensuite :  
👉 **C’est votre encodeur, vos scripts, votre style.**

---

# 🛰️ Compatibilité avec SFTP Malin (EXCLUSIF à `sftpmalin/sftphome:latest`)

FFmpeg Malin est **100% compatible automatiquement** avec le conteneur SFTP suivant :

```text
sftpmalin/sftphome:latest
```

Ce conteneur partage :
- la même architecture `/data/home/<user>`
- le même système `USERS_VAR`
- la même génération des clés
- la même gestion `users.conf`
- la même philosophie “HOME unifié”

✔ mêmes utilisateurs  
✔ mêmes clés SSH  
✔ mêmes scripts  
✔ mêmes menus  
✔ mêmes permissions  
✔ aucun réglage supplémentaire  

Vous pouvez :

1. envoyer les fichiers via **sftpmalin/sftphome:latest**  
2. encoder instantanément via **sftpmalin/ffmpeg:latest**  
3. tout partager automatiquement  

---

# ⚠️ Ancien SFTP (montages séparés) : NON compatible

Les anciens SFTP de type :

```bash
-v /mnt/user/usr1:/home/usr1
-v /mnt/user/usr2:/home/usr2
```

❌ ne sont pas compatibles automatiquement  
❌ ne partagent pas `/data/home/<user>`  
❌ ne partagent pas `users.conf`  
❌ ne partagent pas les clés  

Seule solution :
👉 monter manuellement tous les dossiers pour recréer l’architecture `/data/home/<user>`  
(non recommandé)

---

# 🔗 Liens

GitHub :  
https://github.com/sftpmalin/Media-Remote-Convert

Docker Hub :  
https://hub.docker.com/r/sftpmalin/ffmpeg

---

# 📝 Licence  
**MIT License**
