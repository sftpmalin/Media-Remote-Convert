FROM debian:12

# Cette ligne est obligatoire pour savoir si on est sur PC (amd64) ou autre (arm64)
ARG TARGETARCH

# VÉRIFICATION VISUELLE
RUN echo "TARGET ARCH = $TARGETARCH"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# On met /data/bin en premier dans le PATH
ENV PATH="/data/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"

# 1. DÉPÔTS
RUN sed -i 's/Components: main/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources

# 2. INSTALLATION DES LOGICIELS
RUN apt-get update && \
    PACKAGES="bash tmux ca-certificates procps dos2unix openssh-server \
    python3 python3-pip curl wget git pciutils usbutils passwd acl \
    mkvtoolnix mkvtoolnix-gui mediainfo \
    dialog whiptail python3-tk default-jre-headless mc" && \
    \
    if [ "$TARGETARCH" = "amd64" ]; then \
        echo "C'est un PC (amd64). J'ajoute les pilotes Intel..."; \
        PACKAGES="$PACKAGES intel-media-va-driver-non-free vainfo libva-drm2 libva2 mesa-utils"; \
    else \
        echo "C'est un ARM ($TARGETARCH). Pas besoin des pilotes Intel."; \
    fi && \
    \
    apt-get install -y --no-install-recommends $PACKAGES && \
    pip3 install inquirer prompt-toolkit rich --break-system-packages && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. CRÉATION DE L'UTILISATEUR
RUN groupadd -g 100 users || true
RUN useradd -N -s /bin/bash -u 9000 -g 100 main

RUN mkdir -p /usr/local/share/user_skel
COPY data_users/ /usr/local/share/user_skel/

# 4. LE TRI DES FICHIERS (CORRECTION DU PROBLÈME DE VOLUME)
# On met les fichiers dans un "Coffre-fort" interne qui ne sera pas écrasé par le volume /data
RUN mkdir -p /usr/local/share/ffmpeg_saved

COPY amd64/ /tmp/amd64/
COPY arm64/ /tmp/arm64/

RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "Sauvegarde des binaires AMD64 dans le coffre-fort..."; \
        cp /tmp/amd64/* /usr/local/share/ffmpeg_saved/; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "Sauvegarde des binaires ARM64 dans le coffre-fort..."; \
        cp /tmp/arm64/* /usr/local/share/ffmpeg_saved/; \
    else \
        echo "ERREUR : Je ne connais pas cette architecture ($TARGETARCH) !"; \
        exit 1; \
    fi && \
    chmod +x /usr/local/share/ffmpeg_saved/* && \
    rm -rf /tmp/amd64 /tmp/arm64

# 5. FINITIONS
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN dos2unix /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

RUN mkdir -p /run/sshd

VOLUME /data
EXPOSE 22

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]