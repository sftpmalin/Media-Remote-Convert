#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re

# =======================
# CONFIGURATION GÉNÉRALE
# =======================
HOST_WORKDIR = "/torrent"
IGNORE_DIRS = [".Recycle.Bin"]
EXT = ".mkv"

# Expression régulière pour détecter: Titre.Année.mkv
PATTERN = re.compile(r"^(?P<title>.+?)\.(?P<year>\d{4})\..+\.mkv$", re.IGNORECASE)


def simplify_name(filename):
    match = PATTERN.match(filename)
    if not match:
        return None
    title = match.group("title")
    year = match.group("year")
    return f"{title}.{year}{EXT}"


def process_directory(path, recursive=False):
    renamed = 0

    for root, dirs, files in os.walk(path):
        # Ignore certains dossiers
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]

        if not recursive:
            dirs[:] = []  # Pas de sous-dossiers si non demandé

        for f in sorted(files):
            if not f.lower().endswith(EXT):
                continue

            new_name = simplify_name(f)
            if not new_name:
                print(f"Ignoré : {f}")
                continue

            if new_name != f:
                src = os.path.join(root, f)
                dst = os.path.join(root, new_name)
                print(f"Renommage : {f} -> {new_name}")
                os.rename(src, dst)
                renamed += 1

    if renamed == 0:
        print("\n✅ Aucun fichier à renommer (tout est déjà propre).")
    else:
        print(f"\n✨ Renommage terminé — {renamed} fichier(s) modifié(s).")


if __name__ == "__main__":
    print(f"Dossier traité : {HOST_WORKDIR}")
    process_directory(HOST_WORKDIR, recursive=True)
    print("✅ Terminé.")
