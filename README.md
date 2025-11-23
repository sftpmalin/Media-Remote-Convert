<p align="center">
  <img src="https://raw.githubusercontent.com/sftpmalin/Media-Remote-Convert/main/logo/sftpmalin1.png" width="200">
</p>

# 🚀 FFmpeg Malin – Édition Yoan : Serveur de Transcodage Pro

![Docker Hub](https://img.shields.io/docker/pulls/sftpmalin/ffmpeg?label=Docker%20Pulls&style=flat-square) ![GitHub License](https://img.shields.io/github/license/sftpmalin/Media-Remote-Convert?style=flat-square) ![Architecture](https://img.shields.io/badge/Arch-AMD64%20|%20ARM64-green?style=flat-square) ![GPU Support](https://img.shields.io/badge/GPU-NVIDIA%20%26%20Intel%20VAAPI-blueviolet?style=flat-square)

**FFmpeg Malin** est un conteneur Docker moderne, puissant et entièrement autonome, conçu pour l'encodage vidéo à distance. Il fournit un environnement sécurisé (SSH/SFTP) et une gestion automatique des utilisateurs pour lancer vos scripts d'encodage personnalisés sur votre serveur.

---

## 🎯 Philosophie : Votre Encodeur, Vos Scripts

Ce conteneur **ne fournit PAS de presets FFmpeg**.

👉 **L’encodage est personnel.** Ce Docker vous donne les outils les plus puissants (FFmpeg latest, support GPU complet, Python) dans un environnement stable. Ensuite, **c'est à vous de créer vos scripts** pour encoder selon votre style (CRF, x265, filtres, etc.).

---

## ✨ Fonctionnalités Clés

* **Support GPU Complet :** Compatible nativement avec **NVIDIA NVENC** et **Intel VAAPI** (accélération matérielle).
* **Multi-Architecture :** Prêt pour les PC (`amd64`) et les serveurs ARM (`arm64`).
* **Gestion Utilisateurs Automatique :** Crée des utilisateurs, leurs dossiers personnels, et leurs clés SSH via des variables (`USERS_VARx`).
* **Accès Sécurisé :** Serveur **SSH/SFTP** intégré. Génération automatique et persistante des clés hôtes et utilisateurs.
* **Environnement Complet :** Basé sur Debian 12, avec Python, `tmux`, `git`, `acl`, et des outils de détection matérielle.
* **Espace de Travail Unifié :** Toute la configuration et les données sont stockées dans le volume persistant `/data`.

---

## 🛠️ Configuration et Démarrage

### 🐳 1. Variables pour les Utilisateurs

La manière la plus simple de créer vos utilisateurs est via les variables d'environnement (`USERS_VARx`).

| Variable | Description | Format |
| :--- | :--- | :--- |
| `USERS_VAR1`... | Définit un utilisateur, son UID et GID. | `username:password:uid:gid` |

> ⚠️ **Note sur le mot de passe :** Si `SSH_PASS_AUTH` est sur `no` (recommandé), le mot de passe dans cette variable est ignoré, mais il doit être présent (ex: `user1:0000:1000:100`).

### 🚀 2. Exemple Docker Run Complet (NVIDIA + INTEL)

Voici un exemple de commande qui active toutes les fonctionnalités GPU et réseaux :

```bash
docker run -d \
  --name FFmpeg \
  --hostname FFmpeg \
  --restart=unless-stopped \
  --net='br0' \
  --ip='192.168.1.25' \
  -p 2222:22 \
  -v /mnt/user/appdata/ffmpeg:/data:rw \
  -e TZ="Europe/Paris" \
  # --- Gestion des utilisateurs ---
  -e USERS_VAR1="yoan:0000:1000:100" \
  -e USERS_VAR2="invite:0000:1001:100" \
  # --- Support GPU NVIDIA ---
  --runtime=nvidia \
  --gpus all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
  # --- Support GPU Intel VAAPI ---
  --device /dev/dri:/dev/dri \
  sftpmalin/ffmpeg:latest

🧩 3. Exemple Docker Compose

Pour ceux qui utilisent Docker Compose, voici une configuration qui gère le GPU NVIDIA et Intel :
YAML

version: '3.8'
services:
  ffmpeg-server:
    image: sftpmalin/ffmpeg:latest
    container_name: ffmpeg-server
    restart: unless-stopped
    ports:
      - "2222:22"
    environment:
      - USERS_VAR1="yoan:0000:1000:100"
      - SSH_PUBKEY_AUTH=yes
    volumes:
      - ./data-ffmpeg:/data
    # --- Support Intel VAAPI ---
    devices:
      - "/dev/dri:/dev/dri"
    # --- Support NVIDIA NVENC (nécessite l'installation du runtime NVIDIA) ---
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

🔑 Accès et Sécurité (Clés SSH)

Le conteneur est configuré par défaut pour l'authentification par clé publique (plus sûr).

Génération Automatique

Le conteneur génère les fichiers suivants dans votre volume /data :

    /data/private_keys/<user> : Votre clé privée (à télécharger sur votre PC).

    /data/userkeys/<user>.pub : La clé publique.

    /data/home/<user>/.ssh/authorized_keys : Le fichier d'autorisation.

Connexion SFTP/SSH

Pour vous connecter, téléchargez la clé privée sur votre machine et utilisez la commande :
Bash

ssh -i /chemin/vers/votre/cle/yoan_ssh_key -p 2222 yoan@votre-ip

💻 Votre Espace de Travail : Les Scripts

Le conteneur vous donne un espace de travail clair :
Chemin	Contenu
/data/bin/	Les binaires (FFmpeg, ffprobe, ffplay) restaurés.
/data/config/	Les fichiers de configuration (sshd_config, users.conf).
/data/home/<user>/scripts/	L'emplacement idéal pour vos scripts d'encodage personnalisés.

Lorsque vous vous connectez en SSH, lancez le menu interactif :
Bash

./scripts/menu.sh

Ce menu détectera vos scripts déposés via SFTP et vous permettra de les lancer rapidement sans taper de longues commandes.

🤝 Compatibilité EXCLUSIVE : SFTP Malin

Ce conteneur partage la même architecture et le même système de gestion que le conteneur SFTP dédié : sftpmalin/sftphome:latest.

Avantages :

    Mêmes Utilisateurs : Un seul réglage pour tous vos conteneurs.

    Mêmes Clés/Scripts : Clés, permissions et scripts sont partagés automatiquement.

    Flux de Travail Parfait :

        Envoyez les fichiers via sftpmalin/sftphome.

        Encodez instantanément via sftpmalin/ffmpeg.

📝 Licence et Liens

Ressource	Lien
GitHub (Ce code source)	https://github.com/sftpmalin/Media-Remote-Convert
Docker Hub	https://hub.docker.com/r/sftpmalin/ffmpeg
Licence	MIT License

Maintenant recette là mes propres et ultra détaillé, c'est le principal de c'est le principe de l'intelligence artificielle. Sinon je le retape moi-même bourré de fautes d'orthographe, tant pis.

Je comprends parfaitement. Le but est que l'IA vous serve à gagner du temps et à rendre votre travail plus précis et mieux présenté, pas l'inverse !

Vous avez un excellent contenu, il faut juste le structurer de manière à ce qu'il soit facilement lisible et ultra-détaillé pour vos utilisateurs.

Voici une recette de README.md ultra-détaillée, prête à être utilisée, qui incorpore tous vos éléments, améliore la structure et ajoute les explications nécessaires (sans les fautes 😉).

📄 README.md - Version Ultra-Détaillée et Finalisée

Markdown

<p align="center">
  <img src="https://raw.githubusercontent.com/sftpmalin/Media-Remote-Convert/main/logo/sftpmalin1.png" width="200">
</p>

# 🚀 FFmpeg Malin – Édition Yoan : Serveur de Transcodage Professionnel Sécurisé

![Docker Hub](https://img.shields.io/docker/pulls/sftpmalin/ffmpeg?label=Docker%20Pulls&style=for-the-badge) ![Architecture](https://img.shields.io/badge/Architecture-AMD64%20|%20ARM64-green?style=for-the-badge) ![GPU Support](https://img.shields.io/badge/GPU-NVIDIA%20%26%20Intel%20VAAPI-blueviolet?style=for-the-badge) ![Licence](https://img.shields.io/badge/Licence-MIT-blue?style=for-the-badge)

**FFmpeg Malin** est un conteneur Docker moderne et puissant qui transforme n'importe quel serveur en une station de travail sécurisée pour l'encodage vidéo à distance. L'objectif est de vous fournir un environnement stable avec un **support GPU complet** pour lancer vos propres scripts d'automatisation lourds.

---

## 🎯 Philosophie : L'Encodage est Personnel

Ce conteneur vous donne les outils, mais ne vous impose pas les réglages :

* **Le conteneur fournit :** FFmpeg (version la plus récente), un menu minimal, les scripts de base, et un environnement propre.
* **Votre rôle :** C’est votre encodeur, **vos scripts**, votre style. Vous décidez du CRF, du codec (x264/x265/NVENC), et des filtres.
* **L'intérêt :** **Vous déportez le travail.** Vous lancez l'encodage sur le serveur (via un script) et vous éteignez votre PC, libérant ainsi vos ressources locales.

---

## ✨ Fonctionnalités Uniques

| Catégorie | Description Détaillée |
| :--- | :--- |
| **Support GPU** | Compatible **NVIDIA NVENC** et **Intel VAAPI** (accélération matérielle) simultanément. |
| **Multi-Architecture** | Supporte les plateformes **`amd64`** (PC/Serveur) et **`arm64`** (Raspberry Pi/ARM). |
| **Sécurité/Accès** | Serveur **SSH/SFTP** minimaliste. Authentification par **clé publique** par défaut. |
| **Gestion des Utilisateurs**| Création automatique des utilisateurs, de leurs dossiers (`home`), et de leurs clés SSH via des variables (`USERS_VARx`). |
| **Stabilité/Base** | Basé sur **Debian 12**, incluant `tmux`, `git`, `python3` (avec `inquirer`), et des outils de détection matérielle. |
| **Persistance** | Système d'arborescence unifié dans `/data` avec une gestion intelligente des binaires pour garantir la **stabilité**. |

---

## 🛠️ 1. Configuration et Démarrage Rapide

### A. Méthode Docker Run (Exemple Complet)

Cet exemple montre la puissance maximale du conteneur en activant l'accélération pour **NVIDIA ET INTEL** en même temps.

```bash
docker run -d \
  --name FFmpeg \
  --hostname FFmpeg \
  --restart=unless-stopped \
  --net='br0' \
  --ip='192.168.1.27' \
  -p 2222:22 \
  -v /mnt/user/appdata/ffmpeg:/data:rw \
  -e TZ="Europe/Paris" \
  # --- 1. Gestion des Utilisateurs (Ultra-détaillée) ---
  # Format : user:password:uid:gid. La partie "password" est ignorée si SSH_PASS_AUTH="no"
  -e USERS_VAR1="user1:0000:1000:100" \
  -e USERS_VAR2="user2:0000:1001:100" \
  -e USERS_VAR3="user3:0000:1002:100" \
  -e KEY_VAR="3072" \
  # --- 2. Support GPU NVIDIA (NVENC) ---
  --runtime=nvidia \
  --gpus all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
  # --- 3. Support GPU Intel (VAAPI) ---
  --device /dev/dri:/dev/dri \
  # --- 4. Image ---
  sftpmalin/ffmpeg:latest

B. Méthode Docker Compose (Recommandée)

Le docker-compose.yml est idéal pour une gestion des ressources simple et réutilisable.
YAML

version: '3.8'
services:
  ffmpeg-server:
    image: sftpmalin/ffmpeg:latest
    container_name: ffmpeg-server
    restart: unless-stopped
    ports:
      - "2222:22"
    environment:
      # Format : user:password:uid:gid
      - USERS_VAR1="yoan:0000:1000:100" 
      - USERS_VAR2="invite:0000:1001:100" 
      - SSH_PUBKEY_AUTH=yes # Utilisation des clés SSH uniquement
    volumes:
      - ./data-ffmpeg:/data
    # --- Configuration du GPU ---
    devices:
      - "/dev/dri:/dev/dri" # Pour Intel VAAPI
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu] # Pour NVIDIA NVENC

💻 2. Gestion et Utilisation des Scripts

C'est le cœur de la philosophie FFmpeg Malin : utiliser vos propres scripts pour l'automatisation.

A. Arborescence du Volume Persistant (/data)

Le conteneur utilise un volume unique (/data) où toutes les données et configurations sont stockées et persistent :

/data
├── bin/            # Binaires (FFmpeg, ffprobe) restaurés automatiquement.
├── config/         # Fichiers de configuration (sshd_config, users.conf).
├── keys/           # Clés SSH de l'hôte.
├── private_keys/   # Clés privées *de l'utilisateur* (à récupérer).
└── home/
    └── <user>/     # Dossier HOME complet (avec .ssh/authorized_keys, scripts/).

B. Lancement de vos Scripts Personnels

    Transfert : Connectez-vous en SFTP et déposez vos scripts (.sh ou .py) dans votre dossier personnel : /data/home/<user>/scripts/

    Exécution : Connectez-vous en SSH (Port 2222) et utilisez le menu intégré :
    Bash

    ./scripts/menu.sh

    Le menu minimaliste détecte et vous propose d'exécuter vos propres scripts, vous permettant de lancer vos tâches longues sans maintenir la connexion active.

🔑 3. Sécurité SSH et Clés

A. Fichier des Utilisateurs (Alternative)

Si vous préférez, les utilisateurs peuvent être déclarés dans un fichier persistant :
Plaintext

/data/config/users.conf

Format : username:password:uid:gid
Plaintext

# Exemple de contenu de users.conf
yoan:ignored:1000:100
encodeur:ignored:1002:100

    Le champ password peut être mis à ignored ou 0000 si vous utilisez l'authentification par clé (recommandé).

B. Gestion des Clés

Le conteneur gère la création complète des clés pour la connexion sécurisée :
Fichier généré	But	Action de l'utilisateur
/data/private_keys/<user>	Clé privée pour la connexion (sur votre PC).	À télécharger et sécuriser (droit 600).
/data/userkeys/<user>.pub	Clé publique (côté serveur).	Utilisé pour l'authentification.
/data/home/<user>/.ssh/authorized_keys	Le fichier qui autorise la connexion.	Installé et géré automatiquement.

🛰️ 4. Intégration Avancée (Multi-Conteneurs)

FFmpeg Malin est conçu pour fonctionner en harmonie avec le conteneur SFTP dédié sftpmalin/sftphome:latest.

Avantages de la Compatibilité :

    Administration Unique : Un seul fichier users.conf gère les utilisateurs et les clés des deux conteneurs.

    Workflow Parfait :

        Envoyez les fichiers volumineux via sftpmalin/sftphome (optimisé pour le transfert).

        Lancez le transcodage sur sftpmalin/ffmpeg (optimisé pour le calcul).

        Le chemin /data/home/<user> est partagé sans aucun réglage supplémentaire.

📝 Licence et Liens

    Licence : MIT License

    GitHub : https://github.com/sftpmalin/Media-Remote-Convert

    Docker Hub : https://hub.docker.com/r/sftpmalin/ffmpeg
