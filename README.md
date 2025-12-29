# linux-zen-x1c

Custom Linux kernel optimized for ThinkPad X1 Carbon Gen 11.

## Overview

| Property | Value |
|----------|-------|
| Base | linux-zen 6.18.2.zen2 |
| Target | ThinkPad X1 Carbon Gen 11 |
| CPU | Intel Core i7-1370P (Raptor Lake-P) |
| Build Date | 2025-12-26 |
| Build Method | localmodconfig + menuconfig |

## Size Comparison

| Component | linux-zen-x1c | Stock linux-zen |
|-----------|---------------|-----------------|
| Kernel (vmlinuz) | 18 MB | ~35 MB |
| Initramfs | 24 MB | ~40 MB |
| Package | 30 MB | ~140 MB |
| Loaded modules | ~100 | ~250 |

## Optimizations Applied

### CPU & Scheduler
- [x] Processor family: Intel Raptor Lake
- [x] Preemption: Low-Latency Desktop (PREEMPT)
- [x] Timer: Full dynticks (NO_HZ_FULL)
- [x] High Resolution Timers enabled
- [x] BORE scheduler (zen default)
- [x] Core Scheduling for SMT (P/E-cores)
- [x] "Tune kernel for interactivity" enabled

### Compression
- [x] Kernel compression: ZSTD
- [x] Module compression: ZSTD

### Power Management
- [x] Intel P-State driver
- [x] Intel RAPL (power capping)
- [x] Runtime PM enabled

### Hardware Support (Intel-only)
- [x] Intel Xe graphics (DRM_XE)
- [x] Intel i915 graphics (DRM_I915)
- [x] Intel WiFi (IWLMVM)
- [x] Intel Bluetooth (BT_HCIBTUSB)
- [x] Intel SOF audio
- [x] ThinkPad ACPI
- [x] NVMe storage
- [x] Btrfs filesystem
- [x] dm-crypt (LUKS)
- [x] KVM Intel virtualization

### Disabled (not needed)
- [x] AMD CPU support
- [x] AMD graphics (AMDGPU)
- [x] AMD KVM
- [x] Nvidia graphics
- [x] Most other wireless drivers (Atheros, Broadcom, Realtek, etc.)
- [x] FireWire, PCMCIA, Parallel port, Floppy
- [x] Many unused filesystems
- [x] Server/datacenter networking
- [x] Industrial protocols (CAN, etc.)
- [x] Xen, Hyper-V, VMware guest support

## Files

| File | Purpose |
|------|---------|
| `PKGBUILD` | Package build script with localmodconfig |
| `config` | Base zen kernel config |
| `linux-zen-x1c.conf` | systemd-boot entry |
| `benchmark.sh` | Performance benchmark script |
| `upstream-pkgbuild/` | Original linux-zen PKGBUILD |

## Boot Entry

Installed at `/boot/loader/entries/linux-zen-x1c.conf`:

```ini
title Arch Linux (Zen X1C)
linux /vmlinuz-linux-zen-x1c
initrd /intel-ucode.img
initrd /initramfs-linux-zen-x1c.img
options rd.luks.name=...=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@arch rw
```

## Usage

### Boot into custom kernel
Select "Arch Linux (Zen X1C)" from systemd-boot menu.

### Verify running kernel
```bash
uname -r  # Should show: 6.18.2-zen2-1-zen-x1c
```

### Set as default
```bash
sudo bootctl set-default linux-zen-x1c.conf
```

### Run benchmarks
```bash
~/Workspace/linux-zen-x1c/benchmark.sh
```

## Updating

### When upstream linux-zen updates
```bash
cd ~/Workspace/linux-zen-x1c
git -C upstream-pkgbuild pull
cp upstream-pkgbuild/PKGBUILD .
cp upstream-pkgbuild/config .
# Edit PKGBUILD: change pkgbase, add localmodconfig section
# Update /tmp/modules.lst if needed
MAKEFLAGS="-j18" makepkg -s
sudo pacman -U linux-zen-x1c-*.pkg.tar.zst linux-zen-x1c-headers-*.pkg.tar.zst
```

### Quick rebuild (config changes only)
```bash
cd ~/Workspace/linux-zen-x1c
MAKEFLAGS="-j18" makepkg -ef
sudo pacman -U linux-zen-x1c-*.pkg.tar.zst
```

## Adding Hardware Later

If you connect new hardware that doesn't work:

1. Boot stock kernel: `linux-zen`
2. Connect hardware, check module: `lsmod | grep <module>`
3. Add to modules list: `echo "module_name" >> /tmp/modules.lst`
4. Rebuild kernel

Common modules to add:
| Hardware | Module |
|----------|--------|
| ThinkPad Dock Gen2 ethernet | `r8152` |
| Logitech mice | `hid_logitech_hidpp`, `hid_logitech_dj` |
| USB storage | `usb_storage`, `uas` |

## Rollback

If custom kernel doesn't boot:
1. Select "Arch Linux (Zen)" from boot menu
2. Or remove: `sudo pacman -R linux-zen-x1c linux-zen-x1c-headers`

## Benchmarking

Run on both kernels and compare:
```bash
# Boot stock kernel, run:
~/Workspace/linux-zen-x1c/benchmark.sh

# Reboot into custom kernel, run:
~/Workspace/linux-zen-x1c/benchmark.sh

# Compare results:
diff ~/Workspace/linux-zen-x1c/benchmarks/results-*
```

Metrics compared:
- Boot time (systemd-analyze)
- Kernel/initramfs size
- Loaded modules count
- CPU throughput (sysbench)
- Memory bandwidth
- Scheduler latency (stress-ng)
- Context switch performance
- File I/O throughput
