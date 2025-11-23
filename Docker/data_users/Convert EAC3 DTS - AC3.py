#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import argparse

HOST_WORKDIR = os.path.expanduser("~/Videos")
FFMPEG_PATH = "/data/bin/ffmpeg"
FFPROBE_PATH = "/data/bin/ffprobe"
IGNORE_DIRS = [".Recycle.Bin"]
EXTS = (".mp4", ".mkv", ".avi", ".ts")

SUFFIX_OUT = "_allAC3"

BITRATE_STEREO = "224k"
BITRATE_SURROUND = "640k"


def get_audio_channels_list(src_path):
    probe = subprocess.run(
        [
            FFPROBE_PATH, "-v", "error",
            "-select_streams", "a",
            "-show_entries", "stream=channels",
            "-of", "csv=p=0",
            src_path
        ],
        capture_output=True, text=True
    )

    lines = [l.strip() for l in probe.stdout.splitlines() if l.strip()]

    out = []
    for ln in lines:
        try:
            out.append(int(ln))
        except:
            pass
    return out


def encode_file(src_path, dst_path):

    channels_list = get_audio_channels_list(src_path)

    if not channels_list:
        print("❌ Pas de pistes audio détectées.")
        return

    cmd = [
        FFMPEG_PATH,
        "-hide_banner", "-loglevel", "info", "-stats_period", "5",
        "-i", src_path,
        "-map", "0",
        "-c:v", "copy",
        "-c:s", "copy",
        "-c:d", "copy",
        "-c:t", "copy"
    ]

    # appliquer bitrate par piste audio
    for idx, ch in enumerate(channels_list):
        if ch == 2:
            br = BITRATE_STEREO
            ac = "2"
        else:
            br = BITRATE_SURROUND
            ac = "6"
        
        cmd += [
            f"-b:a:{idx}", br,
            f"-ac:a:{idx}", ac
        ]

    cmd += [
        "-c:a", "ac3",
        dst_path,
        "-y"
    ]

    print("\n🎧 Conversion de toutes les pistes audio vers AC3")
    print("Commande :")
    print(" ".join(cmd))
    print("")

    subprocess.run(cmd)


def process_directory(path, recursive=False):

    os.makedirs(path, exist_ok=True)

    for root, dirs, files in os.walk(path):
        
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]

        if not recursive:
            dirs.clear()

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
                print("⏩ Déjà fait :", f)
                continue

            if os.path.exists(lockfile):
                print("⏩ Lock présent, skip :", f)
                continue

            open(lockfile, "w").close()

            try:
                encode_file(src_path, dst_path)
            finally:
                if os.path.exists(lockfile):
                    os.remove(lockfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convertit TOUTES les pistes audio en AC3 automatiquement")
    parser.add_argument("-sf", "--subfolders", action="store_true",
                        help="Inclure les sous-répertoires")
    args = parser.parse_args()

    process_directory(HOST_WORKDIR, recursive=args.subfolders)
