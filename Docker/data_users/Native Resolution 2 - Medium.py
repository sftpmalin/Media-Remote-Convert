#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import sys
import argparse

# === Configuration générale ===
HOST_WORKDIR = os.path.expanduser("~/Videos")  # expander = essentiel Docker !
FFMPEG_PATH = "/data/bin/ffmpeg"
IGNORE_DIRS = [".Recycle.Bin"]
EXTS = (".mp4", ".mkv", ".avi", ".ts")

# suffix basé sur la QUALITÉ, pas la résolution
SUFFIX_OUT = "_native_CQ24_P6"


def encode_file(src_path, dst_path):
    """Lance FFmpeg et affiche tout en temps réel"""
    cmd = [
        FFMPEG_PATH,
        "-hide_banner", "-loglevel", "info", "-stats_period", "5",
        "-hwaccel", "cuda",
        "-vsync", "0",
        "-i", src_path,
        "-vcodec", "hevc_nvenc",
        "-preset", "p6",
        "-rc", "vbr_hq",
        "-cq", "24",
        "-map", "0:v:0",
        "-map", "0:a",
        "-map", "0:s?",
        "-c:a", "copy",
        "-c:s", "copy",
        dst_path,
        "-y"
    ]

    print(f"\n🎬 Encodage NVIDIA (résolution native) : {os.path.basename(src_path)}")
    print("Commande exécutée :")
    print(" ".join(cmd))
    print("")

    process = subprocess.Popen(cmd)
    process.communicate()
    return process.returncode


def process_directory(path, recursive=False):
    """Parcourt le dossier et encode les fichiers valides"""

    # important : créer si inexistant
    os.makedirs(path, exist_ok=True)

    for root, dirs, files in os.walk(path):
        # Ignore certains dossiers
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]

        if not recursive:
            dirs.clear()

        files.sort()
        for f in files:
            fl = f.lower()
            if not fl.endswith(EXTS):
                continue
            if SUFFIX_OUT.lower() in fl:
                continue

            src_path = os.path.join(root, f)
            base, _ = os.path.splitext(f)
            dst_path = os.path.join(root, f"{base}{SUFFIX_OUT}.mkv")
            lockfile = os.path.join(root, f"{f}.lock")

            if os.path.exists(dst_path):
                print("Déjà fait :", f)
                continue
            if os.path.exists(lockfile):
                print("Lock présent, on saute :", f)
                continue

            open(lockfile, "w").close()

            try:
                encode_file(src_path, dst_path)
            except Exception as e:
                print(f"❌ Erreur pendant l'encodage de {f} : {e}")
            finally:
                if os.path.exists(lockfile):
                    os.remove(lockfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Encode les vidéos à résolution native")
    parser.add_argument("-sf", "--subfolders", action="store_true",
                        help="Inclure les sous-répertoires")
    args = parser.parse_args()

    process_directory(HOST_WORKDIR, recursive=args.subfolders)
