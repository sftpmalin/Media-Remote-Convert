FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
# PATH incluant /usr/sbin (pour useradd)
ENV PATH="/data/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"

# L'installation est sur une seule ligne AVEC 'passwd' (pour useradd) ET 'acl' (pour setfacl)
RUN apt-get update && apt-get install -y --no-install-recommends bash tmux ca-certificates procps dos2unix openssh-server python3 python3-pip curl wget git libva-drm2 libva2 intel-media-va-driver pciutils usbutils passwd acl && pip3 install inquirer --break-system-packages && rm -rf /var/lib/apt/lists/*

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
