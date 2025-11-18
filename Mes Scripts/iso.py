#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import sys

ISO_DIR = "/torrent/isos"
MAKEMKV = "makemkvcon"  # Si ton binaire est ailleurs → mets le chemin complet


def extract_iso(iso_path):
    base = os.path.basename(iso_path)
    name = os.path.splitext(base)[0]
    outdir = os.path.join(ISO_DIR, name)

    print(f"\n📀 ISO détecté : {name}")
    os.makedirs(outdir, exist_ok=True)

    cmd = [
        MAKEMKV, "mkv",
        f"iso:{iso_path}",
        "all",
        f"{outdir}/",
        "--minlength=120"
    ]

    print("→ Exécution :", " ".join(cmd), "\n")

    process = subprocess.run(cmd)

    if process.returncode == 0:
        print(f"✅ Extraction terminée pour : {name}")
    else:
        print(f"❌ Erreur pendant l'extraction de {name}")

    print("---------------------------------------")


def main():
    if not os.path.isdir(ISO_DIR):
        print(f"❌ Le dossier {ISO_DIR} n'existe pas.")
        sys.exit(1)

    iso_files = [
        f for f in os.listdir(ISO_DIR)
        if f.lower().endswith(".iso")
    ]

    if not iso_files:
        print("✅ Aucun fichier ISO trouvé.")
        return

    for iso in iso_files:
        extract_iso(os.path.join(ISO_DIR, iso))

    print("\n✨ Toutes les extractions sont terminées !\n")


if __name__ == "__main__":
    main()
