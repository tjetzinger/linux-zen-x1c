# Kernel Benchmark Comparison

**Hardware**: ThinkPad X1 Carbon Gen 11, Intel Core i7-1370P (6P + 8E cores, 20 threads)
**Last Updated**: 2026-01-03

## Test Conditions

| Condition | Dec 26 (Baseline) | Dec 29 (With Dock) | Dec 31 (Post-Cleanup) | Jan 3 (CachyOS) |
|-----------|-------------------|---------------------|------------------------|-----------------|
| Platform profile | `performance` | `performance` | `performance` | `performance` |
| Power limit | 64W (RAPL) | 64W (RAPL) | 64W (RAPL) | 64W (RAPL) |
| Cooldown | 60s | 60s | 60s | 5s |
| Hardware | Laptop only | Laptop + USB-C Dock | Laptop + USB-C Dock | Laptop + USB-C Dock |
| Kernel | linux-zen | linux-zen-x1c | linux-zen-x1c | linux-cachyos |
| Scheduler | EEVDF | BORE | BORE | scx_bpfland |
| System changes | — | — | Removed laptop-mode-tools, cpupower, acpid, 208 orphans | CachyOS repos (x86-64-v3), sched-ext |

## Results Summary

### Dec 26 - Baseline (Laptop Only)

| Kernel | Version | CPU (ev/s) | Modules | Initramfs |
|--------|---------|------------|---------|-----------|
| Stock zen | 6.18.2-zen2-1-zen | 40,109 | 248 | 29 MB |
| Custom zen-x1c | 6.18.2-zen2-1-zen-x1c | 39,927 | 48 | 23 MB |

**CPU Difference**: -0.45% (effectively identical)

### Dec 29 - With Dock & Peripherals

| Kernel | Version | CPU (ev/s) | Memory (MiB/s) | File I/O (MiB/s) | Ctx Switch (ms) | Modules |
|--------|---------|------------|----------------|------------------|-----------------|---------|
| Custom zen-x1c | 6.18.2-zen2-1-zen-x1c | 31,737 | 8,001 | 21,422 | 16.3 | 240 |

**Connected hardware**: USB-C Dock, Logitech Bluetooth devices, eMeet Luna, YubiKey, SanDisk USB drives

### Dec 31 - Post System Cleanup

| Kernel | Version | CPU (ev/s) | Memory (MiB/s) | File I/O (MiB/s) | Ctx Switch (ms) | Modules |
|--------|---------|------------|----------------|------------------|-----------------|---------|
| Custom zen-x1c | 6.18.2-zen2-1-zen-x1c | 33,284 | 13,923 | 25,023 | 25.6 | 238 |

**Changes from Dec 29**:
- Removed conflicting power services: laptop-mode-tools, cpupower, acpid
- Removed 208 orphaned packages (~2.5 GB)
- Fixed TLP xHCI runtime PM configuration

**Results vs Dec 29**: CPU +4.9%, Memory +74%, File I/O +17%

**Note on context switch**: The 25.6ms result shows high variance (not a regression). Follow-up tests on Dec 31 ranged from 8.9ms to 27.7ms. This benchmark is sensitive to background activity and should not be used for precise comparisons.

### Jan 3 - CachyOS Kernel + sched-ext

| Kernel | Version | Scheduler | CPU (ev/s) | Memory (MiB/s) | File I/O (MiB/s) | Ctx Switch (ms) | Modules |
|--------|---------|-----------|------------|----------------|------------------|-----------------|---------|
| CachyOS | 6.18.2-2-cachyos | scx_bpfland | 35,959 | 14,197 | 23,219 | 22.6 | 260 |
| CachyOS | 6.18.2-2-cachyos | scx_lavd (gaming) | 35,537 | — | — | 19.2 | 260 |

**Changes from Dec 31**:
- Switched to CachyOS repositories (x86-64-v3 optimized packages)
- Installed linux-cachyos kernel
- Enabled sched-ext with scx_bpfland scheduler
- ~1067 packages upgraded to CachyOS x86-64-v3 versions

**Results vs Dec 31 (zen-x1c)**:
- CPU: +8% (35,959 vs 33,284)
- Memory: +2% (14,197 vs 13,923)
- File I/O: -7% (23,219 vs 25,023)
- Context Switch: -12% better (22.6ms vs 25.6ms)

**Scheduler Comparison** (scx_bpfland vs scx_lavd gaming):

| Metric | scx_bpfland | scx_lavd gaming | Winner |
|--------|-------------|-----------------|--------|
| CPU throughput | 35,959 ev/s | 35,537 ev/s | bpfland (+1.2%) |
| Max latency | 5.8 ms | 466.6 ms | bpfland (80x better) |
| Context switch | 22.6 ms | 19.2 ms | lavd (-15%) |

**Note**: scx_lavd gaming mode shows much higher max latency spikes. scx_bpfland provides more consistent performance.

## Performance Analysis

### CPU Performance

| Scenario | Events/sec | Notes |
|----------|------------|-------|
| Laptop only (Dec 26) | ~40,000 | Baseline performance |
| With dock (Dec 29) | ~31,700 | -21% due to USB overhead |
| Post-cleanup (Dec 31) | ~33,300 | +5% improvement from Dec 29 |
| CachyOS + sched-ext (Jan 3) | ~35,900 | +8% vs Dec 31, x86-64-v3 optimized |

The 21% drop with dock connected is expected:
- USB hub interrupt handling
- Additional device polling (HID, audio, storage)
- More kernel modules active (240 vs 48)

The 5% improvement on Dec 31 came from removing conflicting power services.

### Memory & I/O Improvements

| Metric | Stock (Dec 26) | Custom (Dec 29) | Custom (Dec 31) | CachyOS (Jan 3) |
|--------|----------------|-----------------|-----------------|-----------------|
| Memory bandwidth | 5,263 MiB/s | 8,001 MiB/s | 13,923 MiB/s | 14,197 MiB/s |
| File I/O | 7,272 MiB/s | 21,422 MiB/s | 25,023 MiB/s | 23,219 MiB/s |
| Context switches | 31.6 ms | 16.3 ms | 25.6 ms* | 22.6 ms |
| Boot time | 55.0s | 48.2s | 47.6s | 57.8s** |

**Dec 31 vs Dec 26 Stock**: Memory +165%, File I/O +244%, Boot -13%

**CachyOS vs Dec 26 Stock**: Memory +170%, File I/O +219%

*Context switch benchmark shows high variance (8-28ms range). Not reliable for comparisons.
**Boot time includes USB device detection (SanDisk SSD: 8.8s)

### Hyperthreading Analysis

| Threads | Events/sec | Per-Thread | Efficiency |
|---------|------------|------------|------------|
| 6 (P-cores) | 6,839 | 1,140 | 100% |
| 14 (all physical) | 12,908 | 922 | 81% |
| 20 (with HT) | 13,036 | 652 | 57% |

Hyperthreading adds only **1%** total throughput for CPU-bound workloads.

## Custom Kernel Benefits

1. **21% smaller initramfs** (23 MB vs 29 MB)
2. **Faster boot** (-12%, 48s vs 55s)
3. **Better latency** (context switches -48%)
4. **Better I/O** (+195% file read throughput)
5. **Native CPU optimization** (`-march=native` for Raptor Lake)
6. **Reduced attack surface** (only needed drivers)

## Added Hardware Support (Dec 29)

| Hardware | Module | Config |
|----------|--------|--------|
| USB-C Dock Ethernet | `cdc_ether`, `usbnet` | `CONFIG_USB_USBNET`, `CONFIG_USB_NET_CDCETHER` |
| Logitech Bluetooth | `hid_logitech_hidpp`, `hidp` | `CONFIG_HID_LOGITECH_HIDPP`, `CONFIG_BT_HIDP` |
| USB Audio (eMeet Luna) | `snd_usb_audio` | `CONFIG_SND_USB_AUDIO` |
| Bluetooth HID | `hidp`, `uhid` | `CONFIG_BT_HIDP`, `CONFIG_UHID` |

## Power Consumption (RAPL)

| Kernel | Load (14-core) | Idle | Perf/Watt |
|--------|----------------|------|-----------|
| Stock zen | 18W @ 20,035 ev/s | 15W | 1,113 ev/W |
| Custom zen-x1c | 19W @ 20,000 ev/s | 16W | 1,053 ev/W |

*Measurements on AC power, balanced profile*

Stock kernel shows marginally better power efficiency (~5%).

## Summary: Trade-offs (Jan 3)

| Aspect | Stock Zen | Custom zen-x1c | CachyOS + sched-ext |
|--------|-----------|----------------|---------------------|
| CPU Performance | 40,109 ev/s | 33,284 ev/s* | 35,959 ev/s* |
| Memory Bandwidth | 5,263 MiB/s | 13,923 MiB/s | 14,197 MiB/s |
| File I/O | 7,272 MiB/s | 25,023 MiB/s | 23,219 MiB/s |
| Context Switch | 31.6 ms | 25.6 ms | 22.6 ms |
| Max Latency | — | — | 5.8 ms |
| Modules | 248 | 238 | 260 |
| Initramfs | 29 MB | 30 MB | 33 MB |
| Scheduler | EEVDF | BORE | scx_bpfland |

*With USB dock connected (causes ~10-20% CPU overhead)

### CachyOS Benefits

1. **x86-64-v3 optimized packages** - ~1067 packages compiled with AVX2/FMA
2. **sched-ext support** - Dynamic BPF schedulers without reboot
3. **Best memory bandwidth** - 14,197 MiB/s (+170% vs stock)
4. **Best context switching** - 22.6 ms (-28% vs stock)
5. **Lowest max latency** - 5.8 ms with scx_bpfland
6. **CPU improvement** - +8% vs zen-x1c with dock

### Scheduler Recommendation

| Use Case | Recommended Scheduler |
|----------|----------------------|
| Daily desktop | scx_bpfland (Auto) |
| Gaming | scx_bpfland or scx_lavd |
| Low latency (audio) | scx_bpfland (LowLatency) |
| Power saving | scx_lavd (PowerSave) |

**Note**: scx_lavd gaming mode showed 80x higher max latency spikes (466ms vs 5.8ms). For consistent performance, scx_bpfland is recommended.

**Conclusion**: CachyOS with scx_bpfland provides the best overall performance with dock connected. The x86-64-v3 optimizations deliver +8% CPU improvement over custom zen-x1c, while maintaining excellent memory bandwidth (+170% vs stock) and the lowest context switch latency. The sched-ext scheduler provides consistent low-latency performance ideal for desktop use.

## Benchmark Methodology

```bash
# Set performance mode
echo performance | sudo tee /sys/firmware/acpi/platform_profile

# Wait for cooldown
sleep 60

# Run full benchmark
~/Workspace/linux-zen-x1c/benchmark.sh

# Or manual CPU test
sysbench cpu --threads=20 --time=10 run

# Power measurement (RAPL)
START=$(sudo cat /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj)
stress-ng --cpu 14 --timeout 10s
END=$(sudo cat /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj)
echo "Power: $(( (END-START) / 10000000 )) W"
```

**Note**: For accurate CPU comparison, disconnect USB dock and external devices.
