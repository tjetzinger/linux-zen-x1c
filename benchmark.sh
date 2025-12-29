#!/bin/bash
# Kernel Benchmark Script
# Run on both kernels and compare results

KERNEL=$(uname -r)
RESULTS_DIR="$HOME/Workspace/linux-zen-x1c/benchmarks"
RESULTS_FILE="$RESULTS_DIR/results-$KERNEL.txt"

mkdir -p "$RESULTS_DIR"

echo "========================================" | tee "$RESULTS_FILE"
echo "Kernel Benchmark: $KERNEL" | tee -a "$RESULTS_FILE"
echo "Date: $(date)" | tee -a "$RESULTS_FILE"
echo "========================================" | tee -a "$RESULTS_FILE"

# 1. Boot time
echo -e "\n### BOOT TIME ###" | tee -a "$RESULTS_FILE"
systemd-analyze | tee -a "$RESULTS_FILE"
systemd-analyze blame | head -10 | tee -a "$RESULTS_FILE"

# 2. Kernel size
echo -e "\n### KERNEL SIZE ###" | tee -a "$RESULTS_FILE"
ls -lh /boot/vmlinuz-* | tee -a "$RESULTS_FILE"
ls -lh /boot/initramfs-*.img | grep -v fallback | tee -a "$RESULTS_FILE"

# 3. Loaded modules count
echo -e "\n### MODULES ###" | tee -a "$RESULTS_FILE"
echo "Loaded modules: $(lsmod | wc -l)" | tee -a "$RESULTS_FILE"

# 4. CPU benchmark (sysbench)
echo -e "\n### CPU BENCHMARK (sysbench) ###" | tee -a "$RESULTS_FILE"
sysbench cpu --threads=$(nproc) --time=10 run | grep -E "events per|total time:|avg:|max:" | tee -a "$RESULTS_FILE"

# 5. Memory benchmark
echo -e "\n### MEMORY BENCHMARK ###" | tee -a "$RESULTS_FILE"
sysbench memory --threads=$(nproc) --time=10 run | grep -E "transferred|total time:" | tee -a "$RESULTS_FILE"

# 6. Scheduler latency (stress-ng)
echo -e "\n### SCHEDULER LATENCY ###" | tee -a "$RESULTS_FILE"
stress-ng --cpu 4 --timeout 10s --metrics-brief 2>&1 | tail -5 | tee -a "$RESULTS_FILE"

# 7. Context switch performance
echo -e "\n### CONTEXT SWITCHES ###" | tee -a "$RESULTS_FILE"
sysbench threads --threads=64 --time=10 run | grep -E "events per|avg:|max:" | tee -a "$RESULTS_FILE"

# 8. File I/O
echo -e "\n### FILE I/O ###" | tee -a "$RESULTS_FILE"
sysbench fileio --file-test-mode=seqrd --threads=4 --time=10 prepare > /dev/null 2>&1
sysbench fileio --file-test-mode=seqrd --threads=4 --time=10 run | grep -E "read, MiB|written, MiB|reads/s|writes/s" | tee -a "$RESULTS_FILE"
sysbench fileio cleanup > /dev/null 2>&1

# 9. Kernel compile benchmark (optional - takes longer)
# echo -e "\n### KERNEL COMPILE (small) ###" | tee -a "$RESULTS_FILE"
# hyperfine --warmup 1 --runs 3 'make -C /usr/lib/modules/$(uname -r)/build scripts_basic' 2>&1 | tee -a "$RESULTS_FILE"

echo -e "\n========================================" | tee -a "$RESULTS_FILE"
echo "Results saved to: $RESULTS_FILE" | tee -a "$RESULTS_FILE"
echo "========================================" | tee -a "$RESULTS_FILE"
