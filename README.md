# ReSpeaker 4-Mic Linear Array sur Jetson Orin Nano

Ce guide documente le processus d'installation et de configuration du ReSpeaker 4-Mic Linear Array sur un Jetson Orin Nano (module P3767 + carte porteuse P3768) fonctionnant sous L4T R36 (noyau 5.15.148-tegra).

## Présentation

Le ReSpeaker 4-Mic Linear Array utilise le codec AC108. Ce dépôt contient le pilote kernel mis à jour pour être compatible avec le noyau 5.15 des Jetson Orin. Le pilote est compilé en tant que module externe (out-of-tree).

## Configuration Matérielle

- **Module** : Jetson Orin Nano (P3767)
- **Carte Porteuse** : P3768 (Orin Nano Dev Kit)
- **ReSpeaker** : 4-Mic Linear Array (Codec AC108 sur bus I2C 7, adresse 0x3b par défaut)
- **Interface I2S** : I2S2
- **Chemin Audio** : ADMAIF9 → I2S2 → Codec AC108

## Prérequis

- Jetson Orin Nano avec L4T R36 (noyau 5.15.148-tegra)
- En-têtes du noyau installés (`sudo apt install nvidia-l4t-kernel-headers`)
- Outils de compilation : `gcc`, `make`, `dtc`

## Installation du Driver

### 1. Compilation
Dans le répertoire `seeed-voicecard`, lancez la compilation :

```bash
make
```

### 2. Installation
Installez le module compilé dans les répertoires système :

```bash
sudo make install
```

### 3. Chargement
Chargez le module manuellement (ou redémarrez) :

```bash
sudo modprobe snd-soc-ac108
```

Vérifiez la détection :
```bash
lsmod | grep ac108
i2cdetect -y 7
```
L'adresse `3b` (ou `35`) devrait afficher `UU`.

## Configuration du Device Tree (DTB)

Le Device Tree Overlay est nécessaire pour activer l'interface I2S2 et déclarer le codec AC108.

### 1. Compilation des Overlays
Utilisez le script fourni pour compiler et copier les fichiers dans `/boot/` :

```bash
sudo ./compile-dtbo.sh
```

### 2. Activation de l'Overlay
Modifiez votre fichier `/boot/extlinux/extlinux.conf` pour inclure l'overlay correspondant à votre configuration :

**Pour un seul AC108 (4 micros) :**
```text
OVERLAYS /boot/tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array.dtbo
```

**Pour deux AC108 (8 micros - mode TDM) :**
```text
OVERLAYS /boot/tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array-dual.dtbo
```

## Configuration du Routage Audio (XBAR)

Le routage audio interne du Jetson (XBAR) doit être configuré après chaque démarrage pour lier l'interface ADMAIF au bus I2S2.

Exécutez le script de configuration :

```bash
sudo ./configure-respeaker.sh
```

## Utilisation

### Enregistrement Audio (4 canaux)
```bash
arecord -D hw:1,8 -r 48000 -c 4 -f S16_LE -t wav output.wav
```

### Test de Lecture (si haut-parleur connecté à l'AC101)
```bash
aplay -D hw:1,0 -r 48000 -c 2 -f S16_LE test.wav
```

## Dépannage

- **Le module ne se charge pas** : Vérifiez les logs avec `dmesg | grep ac108`. Assurez-vous que les kernel headers correspondent à votre version (`uname -r`).
- **Codec non détecté (i2cdetect)** : Vérifiez les branchements physiques sur le port 40-broches.
- **Pas de périphérique audio dans arecord -l** : Vérifiez que l'overlay est bien chargé dans `extlinux.conf` et que le driver est chargé.
- **Erreur de routage** : Relancez le script `configure-respeaker.sh`.
