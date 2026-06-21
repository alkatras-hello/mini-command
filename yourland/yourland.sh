#!/bin/bash

# ==============================================================================
# YOURLAND v0.1 - Core Engine & Background Monitor
# Developed by: alkatras-hello
# ==============================================================================

# Create directory for system runtime statuses
mkdir -p /tmp/yourland

# Background loop to collect real-time system metrics
update_system_stats() {
    while true; do
        # 1. Get CPU usage percentage
        vmstat 1 2 | tail -n 1 | awk '{print 100 - $15"%"}' > /tmp/yourland/cpu

        # 2. Get RAM usage in Megabytes
        free -m | awk '/Mem:/ {print $3"MB / "$2"MB"}' > /tmp/yourland/ram

        # 3. Detect active Network interface and its status
        NET_INT=$(ip -br link | grep -v "lo" | head -n 1 | awk '{print $1}')
        NET_STAT=$(ip -br link | grep -v "lo" | head -n 1 | awk '{print $2}')
        echo "[$NET_INT] - $NET_STAT" > /tmp/yourland/net

        # 4. Get current system time
        date +"%H:%M:%S" > /tmp/yourland/time

        sleep 1
    done
}

# Start monitoring in the background (Daemon mode)
update_system_stats &
BASH_PID=$!

# Short pause to allow runtime files initialization
sleep 0.5

# Boot the Python Graphical User Interface
python3 yourland.py

# Safe cleanup process after exiting the GUI (Ctrl+C or 'q')
kill $BASH_PID
rm -rf /tmp/yourland
echo "🛡️  YourLand desktop environment stopped safely."
