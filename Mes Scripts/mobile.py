#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import sys
import argparse

HOST_WORKDIR = "/torrent"
FFMPEG_PATH = "ffmpeg"
IGNORE_DIRS = [".Recycle.Bin"]
EXTS = (".mp4", ".mkv", ".avi", ".ts")
SUFFIX_OUT = "_mobile"


def encode_file(src_path, dst_path, copy_subs=True):
    """Encodage mobile stable : scale CPU → encode GPU NVENC."""
    cmd = [
        FFMPEG_PATH,
        "-hide_banner", "-loglevel", "info", "-stats_period", "5",
        "-i", src_path,

        # SCALE CPU (stable pour HEVC/H.264)
        "-vf", "scale=w=640:h=360:force_original_aspect_ratio=decrease,"
               "pad=640:360:(ow-iw)/2:(oh-ih)/2",

        # Encode vidéo GPU (profil mobile)
        "-c:v", "hevc_nvenc",
        "-preset", "p3",
        "-rc", "vbr",
        "-cq", "30",
        "-b:v", "200k",
        "-maxrate", "250k",
        "-bufsize", "400k",

        "-map", "0:v:0",
        "-map", "0:a?",
        "-c:a", "aac", "-b:a", "32k", "-ac", "2"
    ]

    if copy_subs:
        cmd += ["-map", "0:s?", "-c:s", "copy"]
    else:
        cmd += ["-sn"]

    cmd += [dst_path, "-y"]

    print(f"\n🎬 Encodage de {os.path.basename(src_path)}")
    print("Commande exécutée :")
    print(" ".join(cmd), "\n")

    process = subprocess.Popen(cmd, stdout=sys.stdout, stderr=sys.stderr)
    process.wait()
    return process.returncode


def process_directory(path, recursive=False):
    total_processed = 0

    for root, dirs, files in os.walk(path):
        if not recursive:
            dirs[:] = []

        files.sort()

        for f in files:
            fl = f.lower()

            if not fl.endswith(EXTS):
                continue
            if SUFFIX_OUT.lower() in fl:
                continue

            src_path = os.path.join(root, f)
            dst_name = os.path.splitext(f)[0] + SUFFIX_OUT + ".mkv"
            dst_path = os.path.join(root, dst_name)
            lockfile = src_path + ".lock"

            if os.path.exists(dst_path) or os.path.exists(lockfile):
                continue

            total_processed += 1
            open(lockfile, "w").close()

            try:
                code = encode_file(src_path, dst_path, copy_subs=True)
                if code != 0 and os.path.exists(dst_path):
                    print("⚠️  Erreur → nouvelle tentative sans sous-titres")
                    os.remove(dst_path)
                    encode_file(src_path, dst_path, copy_subs=False)

            finally:
                if os.path.exists(lockfile):
                    os.remove(lockfile)

    if total_processed == 0:
        print("\n✅ Aucun fichier à encoder (tout est déjà fait).")
    else:
        print(f"\n✨ Conversion terminée — {total_processed} fichier(s) traité(s).")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-sf", "--subfolders", action="store_true",
                        help="Inclure les sous-répertoires")
    args = parser.parse_args()

    process_directory(HOST_WORKDIR, recursive=args.subfolders)
