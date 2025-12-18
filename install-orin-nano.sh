#!/bin/bash
# Script d'installation automatique pour Jetson Orin Nano
# ReSpeaker 4-Mic Linear Array (AC108)

set -e

echo "--- [1/5] Compilation du driver ---"
make

echo "--- [2/5] Installation du module kernel ---"
sudo make install

echo "--- [3/5] Chargement du module ---"
sudo modprobe snd-soc-ac108 || echo "Le module est déjà chargé ou sera chargé au prochain reboot."

echo "--- [4/5] Compilation et installation des DTBO ---"
if [ -f "./compile-dtbo.sh" ]; then
    sudo ./compile-dtbo.sh
else
    echo "Erreur: compile-dtbo.sh introuvable."
    exit 1
fi

echo "--- [5/5] Configuration du routage audio (XBAR) ---"
if [ -f "./configure-respeaker.sh" ]; then
    sudo ./configure-respeaker.sh
else
    echo "Erreur: configure-respeaker.sh introuvable."
    exit 1
fi

echo ""
echo "==========================================================="
echo " INSTALLATION TERMINÉE "
echo "==========================================================="
echo "IMPORTANT : Assurez-vous d'avoir ajouté l'overlay dans :"
echo "  /boot/extlinux/extlinux.conf"
echo ""
echo "Exemple de ligne à ajouter sous 'LABEL primary' :"
echo "  OVERLAYS /boot/tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array.dtbo"
echo ""
echo "Après avoir modifié le fichier, REDÉMARREZ votre Jetson."
echo "==========================================================="

