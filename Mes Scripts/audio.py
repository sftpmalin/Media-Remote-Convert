#!/usr/bin/env python3
import os
import subprocess

HOST_WORKDIR = "/torrent"
FFMPEG = "/data/bin/ffmpeg"

def ask(text):
    return input(text).strip()

print("===== AUDIO =====")
print("1) AC3")
print("2) EAC3")
print("3) MP3")
print("4) MP2")
print("5) DTS")
print("6) WAV")
print("7) AAC")
print("8) OPUS")
print("")

choix = ask("Choix codec : ")

codecs = {
    "1": "ac3",
    "2": "eac3",
    "3": "mp3",
    "4": "mp2",
    "5": "dts",
    "6": "wav",
    "7": "aac",
    "8": "opus"
}

if choix not in codecs:
    print("Choix invalide.")
    input("Appuyez sur Entrée pour quitter...")
    exit()

codec = codecs[choix]
bitrate = ask("Débit (ex: 192k, 320k, 448k, 1536k...) : ")
sub = ask("Inclure sous-dossiers ? (o/n) : ")

recursive = (sub.lower() == "o")

def detect_layout(path):
    proc = subprocess.Popen(
        [FFMPEG, "-i", path],
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True
    )
    out = proc.stderr.read() + proc.stdout.read()

    for token in ["7.1", "5.1", "2.0", "1.0"]:
        if token in out:
            return token
    return "2.0"

def process_file(src):
    base, ext = os.path.splitext(src)
    layout = detect_layout(src)
    dst = f"{base}_{codec}_{bitrate}_{layout}{ext}"

    if os.path.exists(dst):
        return

    print(f"\n🎵 Encodage de : {os.path.basename(src)}")
    cmd = [
        FFMPEG,
        "-hide_banner", "-loglevel", "info",
        "-i", src,
        "-map", "0:v?", "-map", "0:a?", "-map", "0:s?",
        "-c:v", "copy",
        "-c:s", "copy",
        "-c:a", codec, "-b:a", bitrate,
        "-map_chapters", "0",
        "-y", dst
    ]

    subprocess.run(cmd)

if recursive:
    for root, dirs, files in os.walk(HOST_WORKDIR):
        for f in files:
            if f.lower().endswith((".mp4", ".mkv", ".ts", ".avi")):
                process_file(os.path.join(root, f))
else:
    for f in os.listdir(HOST_WORKDIR):
        if f.lower().endswith((".mp4", ".mkv", ".ts", ".avi")):
            process_file(os.path.join(HOST_WORKDIR, f))

print("\n✨ Terminé.")
input("Appuyez sur Entrée pour revenir au menu...")
