FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/data/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"

# 1. ACTIVATION DES DÉPÔTS NON-FREE (Pour le pilote Intel performant)
# On modifie les sources pour autoriser les logiciels propriétaires (pilotes)
RUN sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources

# 2. INSTALLATION COMPLÈTE (Pilotes, Outils, Python)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash tmux ca-certificates procps dos2unix openssh-server \
    python3 python3-pip curl wget git pciutils usbutils passwd acl \
    \
    # --- PILOTES INTEL (VERSION NON-FREE + VAINFO) ---
    # C'est la commande qui a marché pour vous, intégrée ici :
    intel-media-va-driver-non-free \
    vainfo \
    libva-drm2 \
    libva2 \
    mesa-utils \
    \
    # --- OUTILS MULTIMÉDIA ---
    mkvtoolnix mkvtoolnix-gui \
    mediainfo \
    \
    # --- OUTILS GRAPHIQUES CLI & JAVA ---
    dialog whiptail python3-tk \
    default-jre-headless \
    \
    && pip3 install inquirer prompt-toolkit rich --break-system-packages \
    \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Configuration Utilisateur & Fichiers Locaux
RUN groupadd -g 100 users || true
RUN useradd -N -s /bin/bash -u 9000 -g 100 main

RUN mkdir -p /usr/local/share/user_skel
COPY data_users/ /usr/local/share/user_skel/

RUN mkdir -p /usr/local/bin/ffmpeg_defaults
COPY ffmpeg /usr/local/bin/ffmpeg_defaults/ffmpeg
COPY ffprobe /usr/local/bin/ffmpeg_defaults/ffprobe
COPY ffplay /usr/local/bin/ffmpeg_defaults/ffplay
RUN chmod +x /usr/local/bin/ffmpeg_defaults/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN dos2unix /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

RUN mkdir -p /run/sshd

VOLUME /data
EXPOSE 22

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]