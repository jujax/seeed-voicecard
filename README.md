# ReSpeaker 4-Mic Linear Array on Jetson Orin Nano

This guide documents the process of getting the ReSpeaker 4-Mic Linear Array working on a Jetson Orin Nano (P3767 module + P3768 carrier board) running L4T R36 (kernel 5.15.148-tegra).

## Overview

The ReSpeaker 4-Mic Linear Array uses the AC108 codec chip, which requires a kernel driver that is not included in the standard Jetson kernel. This guide explains how to compile and install the AC108 driver as an out-of-tree kernel module.

## Hardware Configuration

- **Module**: Jetson Orin Nano (P3767)
- **Carrier Board**: P3768 (Orin Nano Dev Kit)
- **ReSpeaker**: 4-Mic Linear Array (AC108 codec on I2C bus 7, address 0x35)
- **I2S Interface**: I2S2
- **Audio Path**: ADMAIF9 → I2S2 → AC108 codec

## Prerequisites

- Jetson Orin Nano with L4T R36 (kernel 5.15.148-tegra)
- Kernel headers available at `/lib/modules/$(uname -r)/build`
- Device tree overlay: `tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array.dtbo`
- Build tools: `gcc`, `make`, `dtc`

## Solution Overview

The original driver source code from the [seeed-voicecard repository](https://github.com/AshaTalambedu/seeed-voicecard/tree/jetson-respeaker-4mic-array-compatible) was designed for older kernels (4.9). This guide adapts it for kernel 5.15.148-tegra by:

1. Compiling the AC108 driver as an out-of-tree kernel module
2. Fixing kernel API compatibility issues
3. Configuring the XBAR audio routing

## Step-by-Step Installation

### 1. Clone the Driver Source

```bash
cd /root
git clone --branch jetson-respeaker-4mic-array-compatible https://github.com/AshaTalambedu/seeed-voicecard.git
cd seeed-voicecard
```

### 2. Kernel API Compatibility Fixes

The driver source code was written for kernel 4.9 and requires updates for kernel 5.15:

#### Fix 1: Replace deprecated `dai->playback_active` and `dai->capture_active`

**File**: `ac108.c` (lines 656, 667-668)

**Old code**:
```c
dai->playback_active, dai->capture_active
```

**New code**:
```c
snd_soc_dai_stream_active(dai, SNDRV_PCM_STREAM_PLAYBACK),
snd_soc_dai_stream_active(dai, SNDRV_PCM_STREAM_CAPTURE)
```

#### Fix 2: Replace deprecated `digital_mute` with `mute_stream`

**File**: `ac108.c` (line 1151)

**Old code**:
```c
.digital_mute = ac108_aif_mute,
```

**New code**:
```c
.mute_stream = ac108_aif_mute,
```

#### Fix 3: Update `ac108_aif_mute` function signature

**File**: `ac108.c` (line 1131)

**Old signature**:
```c
int ac108_aif_mute(struct snd_soc_dai *dai, int mute)
```

**New signature**:
```c
int ac108_aif_mute(struct snd_soc_dai *dai, int mute, int direction)
```

#### Fix 4: Fix fallthrough warning

**File**: `ac108.c` (line 873)

Add `fallthrough;` before the next case statement.

#### Fix 5: Fix `ac101.c` compatibility issues

**File**: `ac101.c` (lines 958-961, 1083)

Replace `codec_dai->active`, `codec_dai->playback_active`, and `codec_dai->capture_active` with `snd_soc_dai_stream_active()` calls.

### 3. Create Makefile

Create a `Makefile` in the `seeed-voicecard` directory:

```makefile
obj-m += snd-soc-ac108.o

snd-soc-ac108-objs := ac108.o ac101.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install
	depmod -a

.PHONY: all clean install
```

### 4. Compile the Driver

```bash
make
```

If compilation succeeds, you should see:
```
LD [M]  /root/seeed-voicecard/snd-soc-ac108.ko
```

### 5. Install the Driver

```bash
sudo make install
```

This installs the module to `/lib/modules/5.15.148-tegra/updates/snd-soc-ac108.ko`.

### 6. Load the Module

```bash
sudo modprobe snd-soc-ac108
```

Verify it's loaded:
```bash
lsmod | grep ac108
```

### 7. Verify Codec Detection

Check that the AC108 codec is detected on I2C bus 7:

```bash
i2cdetect -y 7
```

You should see `UU` at address `35`, indicating the device is in use.

### 8. Configure Audio Routing

After each reboot, configure the XBAR audio routing:

```bash
# Route ADMAIF9 to I2S2
amixer -c 1 cset name="ADMAIF9 Mux" "I2S2"

# Configure I2S2 codec settings
amixer -c 1 cset name="I2S2 codec frame mode" "dsp-a"
amixer -c 1 cset name="I2S2 codec master mode" "cbs-cfs"
amixer -c 1 cset name="I2S2 FSYNC Width" 0

# Set digital volume for all 4 channels
amixer -c 1 cset name="H40-AC CH1 digital volume" 222
amixer -c 1 cset name="H40-AC CH2 digital volume" 222
amixer -c 1 cset name="H40-AC CH3 digital volume" 222
amixer -c 1 cset name="H40-AC CH4 digital volume" 222
```

A configuration script is provided at `/root/configure-respeaker.sh` for convenience.

## Device Tree Configuration

### Available Device Tree Overlays

This repository includes several device tree overlay files:

1. **`p3767-respeaker.dts`** - Single AC108 at address 0x3b (4 microphones)
   - Compiled to: `tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array.dtbo`
   - Compatible: `x-power,ac108_0` at I2C address 0x3b

2. **`p3767-respeaker-dual.dts`** - Dual AC108 configuration (8 microphones)
   - Compiled to: `tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array-dual.dtbo`
   - AC108@3b: `x-power,ac108_0` (master, slots 6,7,0,1)
   - AC108@35: `x-power,ac108_1` (slave, slots 2,3,4,5)
   - Total: 8 channels in TDM mode

3. **`p3737-respeaker.dts`** - Single AC108 at address 0x35 (for AGX Orin)
   - Compiled to: `tegra234-p3737-0000+p3701-0000-audio-respeaker-4-mic-lin-array.dtbo`
   - Compatible: `x-power,ac108_0` at I2C address 0x35

### Compiling Device Tree Overlays

Use the provided script to compile all DTS files and copy them to `/boot/`:

```bash
cd /root/seeed-voicecard
./compile-dtbo.sh
```

To compile a specific file:

```bash
./compile-dtbo.sh p3767-respeaker-dual.dts
```

The script will:
1. Compile each `.dts` file to `.dtbo` format
2. Copy the compiled overlays to `/boot/` with the correct naming convention
3. Set appropriate permissions

### Loading Device Tree Overlays

The device tree overlay must be loaded at boot. Ensure your `/boot/extlinux/extlinux.conf` includes:

**For single AC108 (4 microphones):**
```
LABEL JetsonIO
	MENU LABEL Custom Header Config: <HDR40 ReSpeaker 4 Mic Linear Array>
	FDT /boot/dtb/kernel_tegra234-p3768-0000+p3767-0005-nv-super.dtb
	OVERLAYS /boot/tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array.dtbo
```

**For dual AC108 (8 microphones):**
```
LABEL JetsonIO
	MENU LABEL Custom Header Config: <HDR40 ReSpeaker 8 Mic Array>
	FDT /boot/dtb/kernel_tegra234-p3768-0000+p3767-0005-nv-super.dtb
	OVERLAYS /boot/tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array-dual.dtbo
```

The overlays are compatible with P3768 even though they're named for P3509-A02.

### Dual AC108 Configuration (TDM Mode)

When using two AC108 codecs together:

- **Mode**: Time Division Multiplexing (TDM)
- **Shared Bus**: Both codecs use the same I2S2 bus
- **Slot Allocation**:
  - Codec 0 (0x3b, master): slots 6,7,0,1 → 4 microphones
  - Codec 1 (0x35, slave): slots 2,3,4,5 → 4 microphones
- **Synchronization**: The driver uses `ac108_multi_write()` to synchronize both codecs
- **Total Channels**: 8 channels on the same I2S bus

The driver automatically detects multiple codecs and configures TDM mode when both are present in the device tree.

## Usage

### Recording Audio

**Single AC108 (4 microphones):**

Record 4-channel audio from the ReSpeaker:

```bash
arecord -D hw:1,8 -r 16000 -c 4 -f S16_LE -t wav output.wav
```

**Dual AC108 (8 microphones):**

Record 8-channel audio from both AC108 codecs:

```bash
arecord -D hw:1,8 -r 16000 -c 8 -f S16_LE -t wav output.wav
```

**Parameters**:
- `-D hw:1,8`: Card 1 (APE), Device 8 (ADMAIF9)
- `-r 16000`: Sample rate 16 kHz (or 48000 for higher quality)
- `-c 4` or `-c 8`: Number of channels (4 for single, 8 for dual)
- `-f S16_LE`: 16-bit signed little-endian PCM
- `-t wav`: WAV format

### Verify Audio Devices

List available capture devices:

```bash
arecord -l
```

You should see:
```
card 1: APE [NVIDIA Jetson Orin Nano APE], device 8: tegra-dlink-8 XBAR-ADMAIF9-8 []
```

### Check Driver Status

```bash
# Check if module is loaded
lsmod | grep ac108

# Check dmesg for driver messages
dmesg | grep -i ac108

# Verify codec is detected
i2cdetect -y 7
```

## Post-Reboot Configuration

The XBAR routing configuration is not persistent across reboots. After each reboot, run:

```bash
sudo /root/configure-respeaker.sh
```

Or manually configure as described in step 8 above.

## Troubleshooting

### Module Not Loading

If `modprobe snd-soc-ac108` fails:

1. Check if the module was compiled successfully:
   ```bash
   ls -la /root/seeed-voicecard/snd-soc-ac108.ko
   ```

2. Check kernel logs:
   ```bash
   dmesg | tail -20
   ```

### Codec Not Detected

If `i2cdetect -y 7` shows `--` instead of `UU`:

1. Verify the ReSpeaker is physically connected
2. Check I2C bus 7 is enabled
3. Verify device tree overlay is loaded:
   ```bash
   cat /proc/device-tree/__symbols__/ac108*
   ```

### No Audio Device

If `arecord -l` doesn't show the device:

1. Verify XBAR routing is configured:
   ```bash
   amixer -c 1 cget name="ADMAIF9 Mux"
   ```
   Should show `values=18` (I2S2)

2. Check device tree link:
   ```bash
   cat /proc/device-tree/sound/nvidia-audio-card,dai-link@77/link-name
   ```
   Should show `respeaker-4-mic-array`

3. Verify driver is loaded:
   ```bash
   lsmod | grep ac108
   ```

### Audio Quality Issues

- Adjust digital volume (0-255, default 222):
  ```bash
  amixer -c 1 cset name="H40-AC CH1 digital volume" 200
  ```

- Check sample rate compatibility (16 kHz recommended)

## Files Created

- `/root/seeed-voicecard/`: Driver source code and build files
  - `p3767-respeaker.dts`: Device tree overlay for single AC108 (0x3b)
  - `p3767-respeaker-dual.dts`: Device tree overlay for dual AC108 (0x3b + 0x35)
  - `p3737-respeaker.dts`: Device tree overlay for AGX Orin (0x35)
  - `compile-dtbo.sh`: Script to compile and install device tree overlays
- `/lib/modules/5.15.148-tegra/updates/snd-soc-ac108.ko`: Compiled kernel module
- `/root/configure-respeaker.sh`: Configuration script for audio routing
- `/boot/tegra234-p3767-0000+p3509-a02-audio-respeaker-4-mic-lin-array*.dtbo`: Compiled device tree overlays

## References

- [seeed-voicecard Repository](https://github.com/AshaTalambedu/seeed-voicecard/tree/jetson-respeaker-4mic-array-compatible)
- [NVIDIA Jetson Orin Nano Documentation](https://docs.nvidia.com/jetson/)
- [ALSA Documentation](https://www.alsa-project.org/wiki/Documentation)

## License

The AC108 driver source code is licensed under GPL-3.0, as per the original seeed-voicecard repository.

## Notes

- The driver is compiled as an out-of-tree module, so it needs to be recompiled if the kernel is updated
- The XBAR routing must be reconfigured after each reboot
- The device tree overlay for P3509-A02 works with P3768 due to compatible pin mappings

