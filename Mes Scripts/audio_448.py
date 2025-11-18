#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import sys
import argparse

HOST_WORKDIR = "/torrent"
FFMPEG_PATH = "ffmpeg"
EXTS = (".mp4", ".mkv", ".avi", ".ts")
BITRATE = "448k"
SUFFIX_OUT = "_448"


def encode_file(src_path, dst_path):
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

    print(f"\n🔊 Encodage audio 448k → {os.path.basename(dst_path)}")
    print(" ".join(cmd), "\n")

    p = subprocess.Popen(cmd, stdout=sys.stdout, stderr=sys.stderr)
    p.wait()
    return p.returncode


def process_directory(path, recursive=False):
    total = 0
    for root, dirs, files in os.walk(path):
        if not recursive:
            dirs[:] = []
        for f in sorted(files):
            if not f.lower().endswith(EXTS) or SUFFIX_OUT in f:
                continue

            src = os.path.join(root, f)
            base, ext = os.path.splitext(f)
            dst = os.path.join(root, f"{base}{SUFFIX_OUT}{ext}")
            lock = src + ".lock"

            if os.path.exists(dst) or os.path.exists(lock):
                continue

            total += 1
            open(lock, "w").close()

            try:
                encode_file(src, dst)
            finally:
                if os.path.exists(lock):
                    os.remove(lock)

    if total == 0:
        print("\n✅ Aucun fichier à encoder (tout est déjà fait).")
    else:
        print(f"\n✨ Conversion terminée — {total} fichier(s) traité(s).")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Conversion audio AC3 448k (préserve 5.1)")
    parser.add_argument("-sf", "--subfolders", action="store_true")
    args = parser.parse_args()
    process_directory(HOST_WORKDIR, recursive=args.subfolders)
