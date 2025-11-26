#!/bin/bash
# Script de test I2S2 en loopback (DOUT court-circuité avec DIN)
# Adapté pour Jetson Orin Nano avec carte APE

echo "=== Configuration I2S2 pour test loopback ==="

# Configuration des mux I2S2
echo "Configuration ADMAIF1 Mux -> I2S2..."
amixer -c 1 cset name="ADMAIF1 Mux" "I2S2" > /dev/null 2>&1

echo "Configuration I2S2 Mux -> ADMAIF1..."
amixer -c 1 cset name="I2S2 Mux" "ADMAIF1" > /dev/null 2>&1

# Vérification
echo ""
echo "Vérification de la configuration:"
amixer -c 1 cget name="ADMAIF1 Mux" | grep "values="
amixer -c 1 cget name="I2S2 Mux" | grep "values="

echo ""
echo "=== Génération du fichier de test audio ==="
sox -n -r 48000 -c 2 -b 16 ./input.wav synth 30 sine 1000 vol -6db

if [ ! -f ./input.wav ]; then
    echo "ERREUR: Impossible de créer input.wav"
    exit 1
fi

echo "Fichier input.wav créé (30 secondes, 1000 Hz, -6dB)"
echo ""
echo "=== Test de loopback I2S2 ==="
echo "Assurez-vous que I2S2 DOUT est court-circuité avec I2S2 DIN"
echo ""
echo "Lancement de la lecture en arrière-plan..."
aplay -D hw:"APE",0 ./input.wav > /dev/null 2>&1 &
APLAY_PID=$!

sleep 1

echo "Lancement de l'enregistrement (10 secondes)..."
arecord -D hw:"APE",0 -r 48000 -c 2 -f S16_LE -d 10 ./output.wav > /dev/null 2>&1 &
ARECORD_PID=$!

echo "Enregistrement en cours... (PID: $ARECORD_PID)"
wait $ARECORD_PID
wait $APLAY_PID

echo ""
echo "=== Test terminé ==="
echo "Fichiers générés:"
ls -lh ./input.wav ./output.wav 2>/dev/null

echo ""
echo "Pour analyser avec Audacity:"
echo "  - Ouvrez input.wav et output.wav"
echo "  - Comparez les formes d'onde pour détecter la saturation"
echo ""
echo "Les fichiers sont dans: $(pwd)"

