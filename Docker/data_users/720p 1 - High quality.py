#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import sys
import argparse

# IMPORTANT : expanduser → évite tous les problèmes Docker
HOST_WORKDIR = os.path.expanduser("~/Videos")

FFMPEG_PATH = "/data/bin/ffmpeg"
IGNORE_DIRS = [".Recycle.Bin"]
EXTS = (".mp4", ".mkv", ".avi", ".ts")
SUFFIX_OUT = "_720p_CQ21_P6"  # suffixe à ignorer et à ajouter


def encode_file(src_path, dst_path, copy_subs=True):
    """Lance FFmpeg et affiche tout en temps réel"""
    cmd = [
        FFMPEG_PATH,
        "-hide_banner", "-loglevel", "info", "-stats_period", "5",
        "-hwaccel", "cuda",
        "-vsync", "0",
        "-i", src_path,
        "-vf", "hwupload_cuda,scale_cuda=w=1280:h=720:format=yuv420p:interp_algo=lanczos",
        "-c:v", "hevc_nvenc",
        "-preset", "p6",
        "-rc", "vbr_hq",
        "-cq", "21",
        "-map", "0:v:0",
        "-map", "0:a",
        "-c:a", "copy",
    ]

    if copy_subs:
        cmd += ["-map", "0:s?", "-c:s", "copy"]
    else:
        cmd += ["-sn"]

    cmd += [dst_path, "-y"]

    print(f"\n🎬 Encodage de {os.path.basename(src_path)}")
    print("Commande exécutée :")
    print(" ".join(cmd))
    print("")

    process = subprocess.Popen(cmd)
    process.communicate()
    return process.returncode


def process_directory(path, recursive=False):
    """Traite les fichiers du dossier (et sous-dossiers si demandé)"""

    # important : si le dossier n'existe pas → il est créé
    os.makedirs(path, exist_ok=True)

    for root, dirs, files in os.walk(path):
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

            base, _ = os.path.splitext(f)
            src_path = os.path.join(root, f)
            dst_name = f"{base}{SUFFIX_OUT}.mkv"
            dst_path = os.path.join(root, dst_name)
            lockfile = os.path.join(root, f"{f}.lock")

            if os.path.exists(dst_path):
                print("Déjà fait :", f)
                continue
            if os.path.exists(lockfile):
                print("Lock présent, on saute :", f)
                continue

            open(lockfile, "w").close()

            try:
                code = encode_file(src_path, dst_path, copy_subs=True)
                if code != 0 and os.path.exists(dst_path):
                    print("⚠️  Erreur détectée, suppression du fichier et relance sans sous-titres...")
                    os.remove(dst_path)
                    encode_file(src_path, dst_path, copy_subs=False)

            except Exception as e:
                print(f"❌ Erreur pendant l'encodage de {f} : {e}")
            finally:
                if os.path.exists(lockfile):
                    os.remove(lockfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Encode les vidéos avec ou sans sous-dossiers")
    parser.add_argument("-sf", "--subfolders", action="store_true",
                        help="Inclure les sous-répertoires")
    args = parser.parse_args()

    process_directory(HOST_WORKDIR, recursive=args.subfolders)
