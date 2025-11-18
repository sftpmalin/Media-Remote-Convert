#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import sys
import argparse

HOST_WORKDIR = "/torrent"
FFMPEG_PATH = "ffmpeg"
EXTS = (".mp4", ".mkv", ".avi", ".ts")
BITRATE = "224k"
SUFFIX_OUT = "_224"


def encode_file(src_path, dst_path, copy_subs=True):
    """Encode uniquement l'audio en AC3 224k, vidéo et sous-titres copiés."""
    cmd = [
        FFMPEG_PATH,
        "-hide_banner", "-loglevel", "info", "-stats_period", "5",
        "-i", src_path,

        "-map", "0:v?", "-map", "0:a?", "-map", "0:s?",
        "-c:v", "copy",
        "-c:s", "copy",
        "-c:a", "ac3", "-b:a", BITRATE,

        "-map_chapters", "0",
        "-y", dst_path
    ]

    print(f"\n🎵 Encodage de {os.path.basename(src_path)}")
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
            base, ext = os.path.splitext(f)
            dst_path = os.path.join(root, f"{base}{SUFFIX_OUT}{ext}")
            lockfile = src_path + ".lock"

            if os.path.exists(dst_path) or os.path.exists(lockfile):
                continue

            total_processed += 1
            open(lockfile, "w").close()

            try:
                encode_file(src_path, dst_path)
            finally:
                if os.path.exists(lockfile):
                    os.remove(lockfile)

    if total_processed == 0:
        print("\n✅ Aucun fichier à encoder (tout est déjà fait).")
    else:
        print(f"\n✨ Conversion terminée — {total_processed} fichier(s) traité(s).")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Conversion audio AC3 192k")
    parser.add_argument("-sf", "--subfolders", action="store_true", help="Inclure sous-dossiers")
    args = parser.parse_args()

    process_directory(HOST_WORKDIR, recursive=args.subfolders)
