#!/bin/bash
# Script pour compiler les fichiers DTS et les copier dans /boot/
# Usage: ./compile-dtbo.sh [fichier.dts]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Fonction pour compiler un DTS en DTBO
compile_dtbo() {
    local dts_file="$1"
    local dtbo_file="${dts_file%.dts}.dtbo"
    
    if [ ! -f "$dts_file" ]; then
        echo "❌ Erreur: Fichier $dts_file introuvable"
        return 1
    fi
    
    echo "📦 Compilation de $dts_file..."
    dtc -O dtb -o "$dtbo_file" -@ "$dts_file" 2>&1 | grep -v "^Warning" || true
    
    if [ -f "$dtbo_file" ]; then
        echo "✅ $dtbo_file compilé avec succès"
        return 0
    else
        echo "❌ Erreur lors de la compilation de $dts_file"
        return 1
    fi
}

# Fonction pour copier un DTBO dans /boot/ avec le bon nom
copy_to_boot() {
    local dtbo_file="$1"
    local boot_name=""
    
    # Déterminer le nom dans /boot/ selon le fichier source
    case "$dtbo_file" in
        p3767-respeaker.dtbo)
            boot_name="tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array.dtbo"
            ;;
        p3767-respeaker-dual.dtbo)
            boot_name="tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array-dual.dtbo"
            ;;
        p3737-respeaker.dtbo)
            boot_name="tegra234-p3737-0000+p3701-0000-audio-respeaker-4-mic-lin-array.dtbo"
            ;;
        *)
            # Nom par défaut basé sur le nom du fichier
            boot_name="$(basename "$dtbo_file")"
            ;;
    esac
    
    if [ -f "$dtbo_file" ]; then
        echo "📋 Copie de $dtbo_file vers /boot/$boot_name..."
        sudo cp "$dtbo_file" "/boot/$boot_name"
        sudo chmod 644 "/boot/$boot_name"
        echo "✅ Copié dans /boot/$boot_name"
    else
        echo "❌ Erreur: $dtbo_file introuvable"
        return 1
    fi
}

# Si un fichier spécifique est fourni en argument
if [ $# -gt 0 ]; then
    dts_file="$1"
    if [[ ! "$dts_file" =~ \.dts$ ]]; then
        echo "❌ Erreur: Le fichier doit avoir l'extension .dts"
        exit 1
    fi
    
    compile_dtbo "$dts_file"
    if [ $? -eq 0 ]; then
        dtbo_file="${dts_file%.dts}.dtbo"
        copy_to_boot "$dtbo_file"
    fi
else
    # Compiler tous les fichiers DTS dans le dossier
    echo "🔨 Compilation de tous les fichiers DTS..."
    echo ""
    
    compiled_files=()
    
    for dts_file in *.dts; do
        if [ -f "$dts_file" ]; then
            if compile_dtbo "$dts_file"; then
                dtbo_file="${dts_file%.dts}.dtbo"
                compiled_files+=("$dtbo_file")
            fi
            echo ""
        fi
    done
    
    if [ ${#compiled_files[@]} -eq 0 ]; then
        echo "❌ Aucun fichier DTS trouvé ou compilé"
        exit 1
    fi
    
    echo "📤 Copie des DTBO dans /boot/..."
    echo ""
    
    for dtbo_file in "${compiled_files[@]}"; do
        copy_to_boot "$dtbo_file"
        echo ""
    done
    
    echo "✅ Tous les fichiers ont été compilés et copiés dans /boot/"
    echo ""
    echo "📝 Pour utiliser un overlay, modifiez /boot/extlinux/extlinux.conf :"
    echo "   OVERLAYS /boot/tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array.dtbo"
    echo "   ou"
    echo "   OVERLAYS /boot/tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array-dual.dtbo"
fi

