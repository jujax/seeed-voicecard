#!/bin/bash
# Script de configuration pour ReSpeaker 4-Mic Linear Array sur Jetson Orin Nano
# À exécuter après chaque redémarrage

echo "Configuration du ReSpeaker 4-Mic Linear Array..."

# Configuration du routage XBAR
# Entrée (Capture) : ADMAIF9 -> I2S2
amixer -c 1 cset name="ADMAIF9 Mux" "I2S2" > /dev/null 2>&1
# Sortie (Playback) : ADMAIF1 -> I2S2
amixer -c 1 cset name="ADMAIF1 Mux" "I2S2" > /dev/null 2>&1
amixer -c 1 cset name="I2S2 Mux" "ADMAIF1" > /dev/null 2>&1

# Configuration I2S2 commune
amixer -c 1 cset name="I2S2 codec frame mode" "dsp-a" > /dev/null 2>&1
amixer -c 1 cset name="I2S2 codec master mode" "cbs-cfs" > /dev/null 2>&1
amixer -c 1 cset name="I2S2 FSYNC Width" 0 > /dev/null 2>&1
amixer -c 1 cset name="I2S2 Sample Rate" 48000 > /dev/null 2>&1

# Configuration I2S2 pour enregistrement (Capture) : 48kHz, 16-bit, 4 canaux
amixer -c 1 cset name="I2S2 Capture Audio Bit Format" "16" > /dev/null 2>&1
amixer -c 1 cset name="I2S2 Capture Audio Channels" 4 > /dev/null 2>&1

# Configuration I2S2 pour lecture (Playback) : 48kHz, 16-bit, 2 canaux (stéréo)
amixer -c 1 cset name="I2S2 Playback Audio Bit Format" "16" > /dev/null 2>&1
amixer -c 1 cset name="I2S2 Playback Audio Channels" 2 > /dev/null 2>&1

# Configuration des gains PGA (Programmable Gain Amplifier) pour les microphones
amixer -c 1 cset name="H40-AC ADC1 PGA gain" 20 > /dev/null 2>&1
amixer -c 1 cset name="H40-AC ADC2 PGA gain" 20 > /dev/null 2>&1
amixer -c 1 cset name="H40-AC ADC3 PGA gain" 20 > /dev/null 2>&1
amixer -c 1 cset name="H40-AC ADC4 PGA gain" 20 > /dev/null 2>&1

# Configuration des volumes numériques pour les 4 canaux
amixer -c 1 cset name="H40-AC CH1 digital volume" 222 > /dev/null 2>&1
amixer -c 1 cset name="H40-AC CH2 digital volume" 222 > /dev/null 2>&1
amixer -c 1 cset name="H40-AC CH3 digital volume" 222 > /dev/null 2>&1
amixer -c 1 cset name="H40-AC CH4 digital volume" 222 > /dev/null 2>&1

echo "Configuration terminée !"
echo ""
echo "=== ENTRÉE (Capture) ==="
echo "Pour enregistrer depuis le ReSpeaker 4-Mic Linear Array (48kHz, 16-bit, 4 canaux) :"
echo "  arecord -D hw:1,8 -r 48000 -c 4 -f S16_LE -t wav output.wav"
echo ""
echo "Pour enregistrer à 16kHz (pour reconnaissance vocale) :"
echo "  amixer -c 1 cset name=\"I2S2 Sample Rate\" 16000"
echo "  arecord -D hw:1,8 -r 16000 -c 4 -f S16_LE -t wav output.wav"
echo ""
echo "=== SORTIE (Playback) ==="
echo "Pour lire un fichier audio via I2S2 (48kHz, 16-bit, 2 canaux) :"
echo "  aplay -D hw:1,0 -r 48000 -c 2 -f S16_LE votre_fichier.wav"
echo ""
echo "Pour tester la sortie avec speaker-test :"
echo "  speaker-test -D hw:1,0 -c 2 -t wav"
echo ""
echo "Pour vérifier la configuration :"
echo "  arecord -l  # Entrée: card 1, device 8 (ADMAIF9)"
echo "  aplay -l    # Sortie: card 1, device 0 (ADMAIF1)"

