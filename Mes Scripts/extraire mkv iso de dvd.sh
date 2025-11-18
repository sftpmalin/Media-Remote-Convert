#!/usr/bin/env bash
# ============================================================
# 🚀 Extraction ISO → MKV via MakeMKV (CLI direct, sans docker exec)
# ============================================================

set -e

# --- Couleurs ---
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

echo -e "${GREEN}🚀 Extraction ISO → MKV (MakeMKV CLI local)${NC}\n"

ISO_DIR="/torrent/isos"   # Dossier contenant les ISO

for iso in "$ISO_DIR"/*.ISO "$ISO_DIR"/*.iso; do
    [[ -f "$iso" ]] || continue

    base=$(basename "$iso")
    base="${base%.*}"
    outdir="$ISO_DIR/$base"

    echo -e "📀 ISO détecté : ${YELLOW}$base${NC}"
    mkdir -p "$outdir"

    # Extraction directe, plus de docker exec
    makemkvcon mkv "iso:${iso}" all "${outdir}/" --minlength=120 || {
        echo -e "${RED}❌ Erreur pendant l'extraction de $base${NC}"
        continue
    }

    echo -e "${GREEN}✅ Extraction terminée pour : $base${NC}"
    echo "---------------------------------------"
done

echo -e "${GREEN}✨ Toutes les extractions sont terminées !${NC}"
