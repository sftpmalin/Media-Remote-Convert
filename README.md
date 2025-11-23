<p align="center">
  <img src="https://raw.githubusercontent.com/sftpmalin/Media-Remote-Convert/main/logo/sftpmalin1.png" width="200" alt="Logo FFmpeg Malin">
</p>

<h1>🚀 FFmpeg Malin – Édition Yoan : Serveur de Transcodage Professionnel Sécurisé</h1>

<div class="badges">
    <img src="https://img.shields.io/docker/pulls/sftpmalin/ffmpeg?label=Docker%20Pulls&style=for-the-badge" alt="Docker Pulls"> 
    <img src="https://img.shields.io/badge/Arch-AMD64%20|%20ARM64-green?style=for-the-badge" alt="Architecture"> 
    <img src="https://img.shields.io/badge/GPU-NVIDIA%20%26%20Intel%20VAAPI-blueviolet?style=for-the-badge" alt="Support GPU"> 
    <img src="https://img.shields.io/badge/Licence-MIT-blue?style=for-the-badge" alt="Licence">
</div>

<p>Ce conteneur Docker <strong>FFmpeg Malin</strong> est un serveur de travail conçu pour les tâches d'encodage vidéo lourdes. Il vous permet de <strong>déporter vos traitements</strong> (transcodage) sur votre serveur tout en conservant le contrôle total via SSH/SFTP. L'objectif est de vous fournir l'environnement le plus stable et puissant (FFmpeg latest, support GPU complet) pour exécuter <strong>vos scripts personnels</strong>.</p>

<hr>

<h2>🎯 Philosophie : L'Encodage est Personnel</h2>

<p>Ce conteneur vous donne les outils, mais ne vous impose pas les réglages. <strong>Vous créez vos propres scripts</strong> et décidez du CRF, du codec (x264/x265/NVENC), et des filtres. L'intérêt est de <strong>libérer votre PC</strong> pendant les tâches longues.</p>

<hr>

<h2>✨ Fonctionnalités Uniques</h2>

<table>
    <thead>
        <tr>
            <th>Catégorie</th>
            <th>Description Détaillée</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><strong>Support GPU Avancé</strong></td>
            <td>Compatible <strong>NVIDIA NVENC</strong> et <strong>Intel VAAPI</strong> (accélération matérielle) simultanément.</td>
        </tr>
        <tr>
            <td><strong>Multi-Architecture</strong></td>
            <td>Supporte les plateformes <strong><code>amd64</code></strong> et <strong><code>arm64</code></strong>.</td>
        </tr>
        <tr>
            <td><strong>Gestion Utilisateurs</strong></td>
            <td>Création automatique des utilisateurs et de leurs clés SSH via les variables <code>USERS_VARx</code>.</td>
        </tr>
        <tr>
            <td><strong>Sécurité/Accès</strong></td>
            <td>Serveur <strong>SSH/SFTP</strong> sécurisé. <strong>Authentification par clé publique</strong> par défaut.</td>
        </tr>
        <tr>
            <td><strong>Stabilité</strong></td>
            <td><strong>Système de "Coffre-fort"</strong> pour les binaires : les logiciels sont restaurés automatiquement dans <code>/data/bin</code> même après le montage du volume.</td>
        </tr>
    </tbody>
</table>

<hr>

<h2>🛠️ Installation et Démarrage</h2>

<h3>A. Format des Utilisateurs</h3>
<p>Les utilisateurs sont déclarés via les variables d'environnement. Le mot de passe peut être une valeur neutre (<code>0000</code>, <code>ignored</code>) si vous utilisez les clés SSH.</p>
<ul>
    <li><strong>Format :</strong> <code>username:password:uid:gid</code></li>
</ul>

<h3>B. Exemple Docker Run Complet (NVIDIA + INTEL)</h3>
<div class="code-block">
    <pre>docker run -d \
  --name FFmpeg \
  --hostname FFmpeg \
  --restart=unless-stopped \
  --net='br0' \
  --ip='192.168.1.27' \
  -p 2222:22 \
  -v /mnt/user/appdata/ffmpeg:/data:rw \
  -e TZ="Europe/Paris" \
  -e USERS_VAR1="yoan:0000:1000:100" \
  -e USERS_VAR2="invite:0000:1001:100" \
  --runtime=nvidia \
  --gpus all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
  --device /dev/dri:/dev/dri \
  sftpmalin/ffmpeg:latest</pre>
</div>

<h3>C. Exemple Docker Compose</h3>
<div class="code-block">
    <pre>version: '3.8'
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
    devices:
      - "/dev/dri:/dev/dri" 
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
</pre>
</div>

<hr>

<h2>💻 5. Votre Espace de Travail et Scripts</h2>
<p>L'automatisation est le cœur du projet.</p>
<ol>
    <li><strong>Transfert :</strong> Connectez-vous en <strong>SFTP</strong> (Port 2222).</li>
    <li>Déposez vos scripts (<code>.sh</code>, <code>.py</code>) dans votre dossier : <code> /data/home/&lt;user&gt;/scripts/ </code></li>
    <li><strong>Exécution :</strong> Connectez-vous en <strong>SSH</strong> et lancez le menu intégré :</li>
</ol>
<div class="code-block">
    <pre>./scripts/menu.sh</pre>
</div>

<h3>Structure de <code>/data</code></h3>
<table>
    <thead>
        <tr>
            <th>Chemin</th>
            <th>Contenu</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>/data/bin/</code></td>
            <td>Les binaires (FFmpeg, ffprobe) restaurés automatiquement.</td>
        </tr>
        <tr>
            <td><code>/data/private_keys/</code></td>
            <td><strong>Vos clés privées</strong> générées (à récupérer pour se connecter).</td>
        </tr>
    </tbody>
</table>

<hr>

<h2>🔑 6. Sécurité et Accès</h2>
<p>Le conteneur génère les clés nécessaires pour un accès sécurisé.</p>
<ul>
    <li><strong>Clé Privée :</strong> Se trouve dans <code>/data/private_keys/&lt;user&gt;</code> (sur votre serveur).</li>
    <li><strong>Connexion SSH :</strong> Téléchargez cette clé sur votre PC et utilisez la commande :</li>
</ul>
<div class="code-block">
    <pre>ssh -i /chemin/vers/votre/cle/user_ssh_key -p 2222 user@votre-ip</pre>
</div>

<hr>

<h2>🛰️ 7. Intégration Avancée (SFTP Malin)</h2>
<p>Ce conteneur est <strong>100% compatible</strong> avec le conteneur SFTP dédié <code>sftpmalin/sftphome:latest</code>. Le même fichier de configuration (<code>users.conf</code>) et le même jeu de clés SSH sont gérés pour les deux services, permettant un <strong>workflow parfait</strong> (Transfert avec SFTP Home, Traitement avec FFmpeg Malin).</p>

<hr>

<h2>🔗 Liens</h2>
<ul>
    <li><strong>GitHub :</strong> <code>https://github.com/sftpmalin/Media-Remote-Convert</code></li>
    <li><strong>Docker Hub :</strong> <code>https://hub.docker.com/r/sftpmalin/ffmpeg</code></li>
    <li><strong>Licence :</strong> MIT License</li>
</ul>

</body>
</html>
