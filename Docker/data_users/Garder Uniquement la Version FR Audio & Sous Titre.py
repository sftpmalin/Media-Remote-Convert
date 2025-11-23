#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import argparse
from datetime import datetime

# ================= CONFIG =================
FFMPEG_PATH = "/data/bin/ffmpeg"
FFPROBE_PATH = "/data/bin/ffprobe"
IGNORE_DIRS = [".Recycle.Bin"]
WORKDIRS = [os.path.expanduser("~/Videos")]
OUTPUT_DIR = os.path.expanduser("~/Videos")
EXTS = (".mp4", ".mkv", ".avi", ".ts")

SUFFIX_OUT = "_FR"

KEEP_FOLDER_STRUCTURE = True


# ================= LOGIQUE PRINCIPALE =================
def process_directory(folder, recursive=False):

    os.makedirs(folder, exist_ok=True)

    for root, dirs, files in os.walk(folder):

        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]

        if not recursive:
            dirs.clear()

        for filename in files:
            fl = filename.lower()
            if not fl.endswith(EXTS):
                continue
            if SUFFIX_OUT.lower() in fl:
                continue

            src_path = os.path.join(root, filename)
            base, _ = os.path.splitext(filename)

            # dossier de sortie
            if recursive and KEEP_FOLDER_STRUCTURE:
                dst_path = os.path.join(root, f"{base}{SUFFIX_OUT}.mkv")
            else:
                dst_path = os.path.join(OUTPUT_DIR, f"{base}{SUFFIX_OUT}.mkv")

            if os.path.exists(dst_path):
                print(f"⏩ Déjà traité → {filename}")
                continue

            # Analyse avec ffprobe
            probe = subprocess.run(
                [
                    FFPROBE_PATH, "-v", "error",
                    "-show_entries", "stream=index,codec_type:stream_tags=language",
                    "-of", "csv=p=0", src_path
                ],
                capture_output=True, text=True
            )

            lines = [l for l in probe.stdout.splitlines() if l.strip()]

            audio_fr = []
            sub_fr = []

            for line in lines:
                parts = line.split(",")
                if len(parts) < 2:
                    continue

                try:
                    idx = int(parts[0])
                except:
                    continue

                codec = parts[1].strip().lower()
                is_fr = any(k in line.lower() for k in ["fra", "fre", "fr", "french"])

                if codec == "audio" and is_fr:
                    audio_fr.append(idx)
                elif codec == "subtitle" and is_fr:
                    sub_fr.append(idx)

            if not audio_fr:
                print(f"⏩ Pas de piste FR → skip : {filename}")
                continue

            print(f"\n🎬 Extraction FR only : {filename}")

            maps = ["-map", "0:v:0"]

            for idx in audio_fr:
                maps += ["-map", f"0:{idx}"]

            for idx in sub_fr:
                maps += ["-map", f"0:{idx}"]

            cmd = [
                FFMPEG_PATH,
                "-hide_banner", "-loglevel", "info", "-stats_period", "5",
                "-i", src_path,
                *maps,
                "-c", "copy",
                dst_path, "-y"
            ]

            try:
                subprocess.run(cmd, check=True)
                print(f"✅ Généré : {dst_path}")
            except:
                print(f"❌ Erreur sur : {filename}")


# ================= MAIN =================
def main():
    parser = argparse.ArgumentParser(description="Extraction FR-only")
    parser.add_argument("-sf", "--subfolders", action="store_true",
                        help="Inclure sous-dossiers")
    args = parser.parse_args()

    for folder in WORKDIRS:
        print(f"📁 Traitement : {folder}")
        process_directory(folder, recursive=args.subfolders)


if __name__ == "__main__":
    print(f"=== [START] {datetime.now():%H:%M:%S} ===")
    main()
    print(f"--- [END] {datetime.now():%H:%M:%S} ---")
