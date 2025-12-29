# linux-zen-x1c

Custom Linux kernel optimized for ThinkPad X1 Carbon Gen 11 using localmodconfig.

## Overview

| Property | Value |
|----------|-------|
| Base | linux-zen 6.18.2.zen2 |
| Target | ThinkPad X1 Carbon Gen 11 |
| CPU | Intel Core i7-1370P (Raptor Lake-P) |
| Build Method | localmodconfig + menuconfig |
| Last Updated | 2025-12-29 |

## Benefits

| Metric | Stock | Custom | Improvement |
|--------|-------|--------|-------------|
| Initramfs | 29 MB | 23 MB | **-21%** |
| Boot time | 55s | 48s | **-12%** |
| Context switches | 31.6ms | 16.3ms | **-48%** |
| File I/O | 7,272 MiB/s | 21,422 MiB/s | **+195%** |
| Memory bandwidth | 5,263 MiB/s | 8,001 MiB/s | **+52%** |
| CPU performance | ~40,000 ev/s | ~40,000 ev/s | Identical |

## Hardware Support

### Enabled

**CPU & Power**
- Intel Raptor Lake (native optimizations)
- Intel P-State + RAPL
- Low-latency preemption (PREEMPT)
- Full dynticks (NO_HZ_FULL)
- BORE scheduler

**Graphics**
- Intel Xe (DRM_XE)
- Intel i915 (DRM_I915)

**Audio**
- Intel SOF (sof-hda-dsp)
- USB Audio (eMeet Luna, dock audio)

**Networking**
- Intel WiFi (iwlmvm)
- Intel Bluetooth
- USB-C Dock Ethernet (cdc_ether)

**Input**
- Logitech Bluetooth (hid_logitech_hidpp)
- Logitech USB receiver (hid_logitech_dj)
- Bluetooth HID (hidp, uhid)

**Storage**
- NVMe
- Btrfs, ext4
- dm-crypt (LUKS)
- USB storage (uas)

**Other**
- ThinkPad ACPI
- KVM Intel virtualization
- Intel HW RNG

### Disabled

- AMD CPU/GPU/KVM
- Nvidia graphics
- Intel AVS audio (conflicts with SOF)
- Other wireless drivers
- Legacy hardware (FireWire, PCMCIA, etc.)
- Server/datacenter features

## Files

| File | Purpose |
|------|---------|
| `PKGBUILD` | Package build script with localmodconfig |
| `config` | Kernel configuration |
| `benchmark.sh` | Performance benchmark script |
| `benchmark-results/` | Benchmark comparison documentation |
| `benchmarks/` | Raw benchmark results |
| `linux-zen-x1c.conf` | systemd-boot entry template |

## Installation

### Build

```bash
cd ~/Workspace/linux-zen-x1c

# Capture currently loaded modules (boot stock kernel first if adding hardware)
lsmod > /tmp/modules.lst

# Build
MAKEFLAGS="-j$(nproc)" makepkg -s

# Install
sudo pacman -U linux-zen-x1c-*.pkg.tar.zst linux-zen-x1c-headers-*.pkg.tar.zst
```

### Boot Entry

Copy to `/boot/loader/entries/linux-zen-x1c.conf`:

```ini
title Arch Linux (Zen X1C)
linux /vmlinuz-linux-zen-x1c
initrd /intel-ucode.img
initrd /initramfs-linux-zen-x1c.img
options rd.luks.name=<UUID>=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@arch rw
```

## Usage

### Boot into custom kernel
Select "Arch Linux (Zen X1C)" from systemd-boot menu.

### Verify
```bash
uname -r  # 6.18.2-zen2-1-zen-x1c
```

### Set as default
```bash
sudo bootctl set-default linux-zen-x1c.conf
```

## Updating

### When upstream linux-zen updates

```bash
cd ~/Workspace/linux-zen-x1c

# Get new PKGBUILD from AUR or upstream
# Edit: change pkgbase to linux-zen-x1c
# Edit: add localmodconfig section in prepare()

# Capture modules
lsmod > /tmp/modules.lst

# Build and install
MAKEFLAGS="-j$(nproc)" makepkg -s
sudo pacman -U linux-zen-x1c-*.pkg.tar.zst linux-zen-x1c-headers-*.pkg.tar.zst
```

### Quick rebuild (config changes only)

```bash
cd ~/Workspace/linux-zen-x1c
MAKEFLAGS="-j$(nproc)" makepkg -ef
sudo pacman -U linux-zen-x1c-*.pkg.tar.zst linux-zen-x1c-headers-*.pkg.tar.zst
```

## Adding Hardware

If new hardware doesn't work:

1. Boot stock kernel (`linux-zen`)
2. Connect hardware
3. Find module: `lsmod | grep <name>`
4. Add config:
   ```bash
   cd ~/Workspace/linux-zen-x1c/src/linux-*/
   scripts/config --module CONFIG_<NAME>
   make olddefconfig
   ```
5. Rebuild kernel

### Supported Hardware

| Hardware | Module | Config |
|----------|--------|--------|
| Dock Ethernet | `cdc_ether`, `usbnet` | `CONFIG_USB_USBNET`, `CONFIG_USB_NET_CDCETHER` |
| Logitech Bluetooth | `hid_logitech_hidpp`, `hidp` | `CONFIG_HID_LOGITECH_HIDPP`, `CONFIG_BT_HIDP` |
| Logitech USB receiver | `hid_logitech_dj` | `CONFIG_HID_LOGITECH_DJ` |
| USB Audio | `snd_usb_audio` | `CONFIG_SND_USB_AUDIO` |
| Bluetooth HID | `hidp`, `uhid` | `CONFIG_BT_HIDP`, `CONFIG_UHID` |
| USB Storage | `usb_storage`, `uas` | `CONFIG_USB_STORAGE`, `CONFIG_USB_UAS` |

## Benchmarking

```bash
# Set performance mode
echo performance | sudo tee /sys/firmware/acpi/platform_profile

# Cooldown
sleep 60

# Run benchmark
~/Workspace/linux-zen-x1c/benchmark.sh

# Results saved to:
# ~/Workspace/linux-zen-x1c/benchmarks/results-$(uname -r).txt
```

See [benchmark-results/comparison.md](benchmark-results/comparison.md) for detailed analysis.

## Troubleshooting

### No audio
Ensure Intel AVS is disabled and SOF is enabled:
```bash
scripts/config --disable CONFIG_SND_SOC_INTEL_AVS
scripts/config --module CONFIG_SND_SOC_SOF_ALDERLAKE
```

### Sudo password loop (fingerprint)
Enable Intel HW RNG:
```bash
scripts/config --module CONFIG_HW_RANDOM_INTEL
```

### Bluetooth devices not working
Enable Bluetooth HID:
```bash
scripts/config --module CONFIG_BT_HIDP
scripts/config --module CONFIG_UHID
```

### Rollback
Boot "Arch Linux (Zen)" from boot menu, or:
```bash
sudo pacman -R linux-zen-x1c linux-zen-x1c-headers
```

## License

Kernel sources are GPL-2.0. Build scripts and documentation are MIT.
