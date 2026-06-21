#!/bin/sh
# ========================================================
# Speed-test - speed test pc and WiFi
Developed
#
#
# ========================================================



# 1. PC SPEED TEST (DISK DRIVE)
echo "[1/3] Testing disk drive speed..."
if command -v dd >/dev/null 2>&1; then
    # Write 50MB of zeros to disk and measure real write speed
    dd if=/dev/zero of=test_speed_file.tmp bs=1M count=50 conv=fdatasync 2>&1 | grep -E 'copied|скопійовано|bytes' || echo " 💾 Disk test completed."
    rm -f test_speed_file.tmp
else
    echo " ❌ Tool 'dd' not found."
fi

# 2. PC SPEED TEST (CPU PERFORMANCE)
echo ""
echo "[2/3] Testing CPU performance..."
if command -v bc >/dev/null 2>&1; then
    # Calculate Pi to 2000 digits to bench the CPU
    start_cpu=$(date +%s.%N)
    echo "scale=2000; 4*a(1)" | bc -l > /dev/null
    end_cpu=$(date +%s.%N)
    cpu_time=$(echo "$end_cpu - $start_cpu" | bc)
    echo " 💻 CPU Time (Pi to 2000 digits): $cpu_time sec (lower = better)"
else
    # Alternative benchmark using md5sum if bc is missing
    start_cpu=$(date +%s)
    dd if=/dev/zero bs=1M count=100 2>/dev/null | md5sum > /dev/null
    end_cpu=$(date +%s)
    cpu_time=$((end_cpu - start_cpu))
    echo " 💻 Hashing 100MB of data took: $cpu_time sec"
fi

# 3. INTERNET & PING TEST
echo ""
echo "[3/3] Testing internet connection..."
if command -v curl >/dev/null 2>&1; then
    # Download 10MB test file from Cloudflare CDN
    echo " 🌐 Downloading 10MB file via Cloudflare CDN..."
    speed_bytes=$(curl -L -s -o /dev/null -w "%{speed_download}" "https://speed.cloudflare.com/__down?bytes=10485760")

    # Convert Bytes/sec to Megabits/sec (Mbit/s)
    if command -v bc >/dev/null 2>&1; then
        speed_mbit=$(echo "scale=2; ($speed_bytes * 8) / 1024 / 1024" | bc)
        echo " 🚀 Estimated speed: $speed_mbit Mbit/s"
    else
        speed_mbit=$((speed_bytes * 8 / 1024 / 1024))
        echo " 🚀 Estimated speed: ~$speed_mbit Mbit/s"
    fi
else
    echo " ❌ Tool 'curl' is required. Install it via: sudo apt install curl"
fi

# Quick ping check
echo ""
echo " Checking latency (Ping to Cloudflare DNS)..."
ping -c 3 1.1.1.1 | tail -n 2

echo "========================================"
