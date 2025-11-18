#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import argparse
from datetime import datetime

# ================= CONFIG =================
FFMPEG_PATH = "ffmpeg"
FFPROBE_PATH = "ffprobe"
IGNORE_DIRS = [".Recycle.Bin"]
WORKDIRS = ["/torrent"]
OUTPUT_DIR = "/torrent"
EXTS = (".mp4", ".mkv", ".avi", ".ts")
SUFFIX_OUT = "_FR"

# Si True → en mode -sf, on garde le fichier converti dans le même dossier d'origine
KEEP_FOLDER_STRUCTURE = True


# ================= LOGIQUE PRINCIPALE =================
def process_directory(folder, recursive=False):
    for root, dirs, files in os.walk(folder):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]

        if not recursive:
            dirs.clear()

        for filename in files:
            fl = filename.lower()
            if not fl.endswith(EXTS):
                continue
            if SUFFIX_OUT.lower() in fl:
                continue  # évite les sorties déjà générées

            src_path = os.path.join(root, filename)
            base, _ = os.path.splitext(filename)

            # --- Correction : placement intelligent du fichier de sortie ---
            if recursive and KEEP_FOLDER_STRUCTURE:
                dst_path = os.path.join(root, f"{base}{SUFFIX_OUT}.mkv")
            else:
                dst_path = os.path.join(OUTPUT_DIR, f"{base}{SUFFIX_OUT}.mkv")

            if os.path.isfile(dst_path):
                print(f"⏩ Déjà traité → {dst_path}")
                continue

            # ffprobe
            probe = subprocess.run(
                [
                    FFPROBE_PATH, "-v", "error",
                    "-show_entries", "stream=index,codec_type:stream_tags=language",
                    "-of", "csv=p=0", src_path
                ],
                capture_output=True, text=True
            )

            lines = [ln for ln in probe.stdout.strip().split("\n") if ln]

            audio_fr = []
            audio_non_fr = []
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
                lang_line = line.lower()
                is_fr = any(tag in lang_line for tag in ["fra", "fre", "fr", "french"])

                if codec == "audio":
                    (audio_fr if is_fr else audio_non_fr).append(idx)
                elif codec == "subtitle":
                    if is_fr:
                        sub_fr.append(idx)

            if audio_fr and not audio_non_fr:
                print(f"⏩ Déjà FR only → skip : {filename}")
                continue

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
                "-map_chapters", "0",
                dst_path, "-y"
            ]

            try:
                subprocess.run(cmd, check=True)
                print(f"✅ Généré : {dst_path}")
            except subprocess.CalledProcessError:
                print(f"❌ Erreur sur : {filename}")


# ================= MAIN =================
def main():
    parser = argparse.ArgumentParser(description="Extraction FR-only sur fichiers multi-langues")
    parser.add_argument("-sf", "--subfolders", action="store_true",
                        help="Inclure les sous-dossiers")
    args = parser.parse_args()

    for folder in WORKDIRS:
        if not os.path.isdir(folder):
            print(f"❌ Dossier introuvable : {folder}")
            continue

        print(f"📁 Traitement du dossier : {folder}")
        process_directory(folder, recursive=args.subfolders)


if __name__ == "__main__":
    print(f"=== [START] Extraction FR {datetime.now():%H:%M:%S} ===")
    main()
    print(f"--- [END] {datetime.now():%H:%M:%S} ---")
