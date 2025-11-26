#!/bin/bash
 # Script pour tester toutes les sorties audio disponibles avec speaker-test

echo "Test de toutes les sorties audio disponibles avec speaker-test..."
echo "Appuyez sur Ctrl+C pour arrêter chaque test"
echo ""

# Lister tous les périphériques
aplay -l | grep "card.*device" | while read line; do
    CARD=$(echo $line | sed -n 's/.*card \([0-9]*\):.*/\1/p')
    DEVICE=$(echo $line | sed -n 's/.*device \([0-9]*\):.*/\1/p')
    NAME=$(echo $line | sed -n 's/.*device [0-9]*: \(.*\)/\1/p')
    
    if [ -n "$CARD" ] && [ -n "$DEVICE" ]; then
        echo "=========================================="
        echo "Test: Card $CARD, Device $DEVICE"
        echo "Nom: $NAME"
        echo "Commande: speaker-test -D hw:$CARD,$DEVICE -c 2 -t wav -l 1 -s 1"
        echo "Appuyez sur Ctrl+C pour passer au suivant..."
        echo ""
        
        timeout 5 speaker-test -D hw:$CARD,$DEVICE -c 2 -t wav -l 1 -s 1 2>&1 || \
        timeout 5 speaker-test -D plughw:$CARD,$DEVICE -c 2 -t wav -l 1 -s 1 2>&1
        
        echo ""
        read -t 2 -p "Avez-vous entendu du son ? (o/n) " answer
        if [ "$answer" = "o" ] || [ "$answer" = "O" ]; then
            echo "✓ Cette sortie fonctionne !"
            echo "Utilisez: speaker-test -D hw:$CARD,$DEVICE -c 2 -t wav"
            echo "Ou: aplay -D hw:$CARD,$DEVICE votre_fichier.wav"
            break
        fi
        echo ""
    fi
done

echo ""
echo "Test terminé !"

