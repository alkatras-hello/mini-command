#!/bin/bash

# ==============================================================================
# FAKE-WIFI-DEVICE - Virtual Wi-Fi Simulator with MAC/IP Rotation & Tor Proxy
# Developed by: alkatras-hello
# ==============================================================================

# Check if running with root privileges (sudo)
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Please run this script with sudo!"
    exit 1
fi

# File to store the background process PID for later termination
PID_FILE="/var/run/fake_wifi_rotate.pid"

# Function to generate a random MAC address
generate_random_mac() {
    printf '02:%02x:%02x:%02x:%02x:%02x\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# Function to generate a random local IP address (192.168.X.X)
generate_random_ip() {
    echo "192.168.$((RANDOM%254 + 1)).$((RANDOM%254 + 1))"
}

# Background rotation loop execution
rotate_loop() {
    # Give the kernel module 2 seconds to properly initialize
    sleep 2

    # Identify the created virtual wireless interfaces
    IFACES=$(ip link show | grep -o -E "wlan[0-9]+")

    if [ -z "$IFACES" ]; then
        echo "[$(date '+%H:%M:%S')] ⚠️ No wlan interfaces found for rotation." >> /var/log/fake-wifi.log
        exit 1
    fi

    # --- IMMEDIATELY LOG INITIAL STATUS ---
    echo "[$(date '+%H:%M:%S')] 🚀 Fake Wi-Fi daemon successfully started!" >> /var/log/fake-wifi.log
    for iface in $IFACES; do
        CURRENT_MAC=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')
        echo "[$(date '+%H:%M:%S')] 📡 Monitoring interface: $iface (Initial MAC: $CURRENT_MAC)" >> /var/log/fake-wifi.log
    done
    echo "[$(date '+%H:%M:%S')] ⏳ Next rotation in 20 minutes..." >> /var/log/fake-wifi.log

    while true; do
        # Sleep for 20 minutes (1200 seconds) before the next rotation
        sleep 1200

        # --- NOTIFICATION SYSTEM ---
        MSG="⚠️ Attention! Rotating MAC, IP, and Tor Identity NOW..."
        echo "[$(date '+%H:%M:%S')] $MSG" >> /var/log/fake-wifi.log

        # Audio alert to TTY consoles
        printf "\a" > /dev/tty1 2>/dev/null
        printf "\a" > /dev/tty3 2>/dev/null

        # GUI Desktop notification
        CURRENT_USER=$(who | awk '{print $1}' | head -n1)
        USER_ID=$(id -u "$CURRENT_USER")
        DBUS_LAUNCH="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus"
        sudo -u "$CURRENT_USER" $DBUS_LAUNCH notify-send "Fake Wi-Fi & Tor" "$MSG" &>/dev/null

        # --- TOR IDENTITY REFRESH ---
        if systemctl is-active --quiet tor; then
            systemctl reload tor &>/dev/null
            echo "[$(date '+%H:%M:%S')] 🧅 Tor identity refreshed (New external WAN IP requested)." >> /var/log/fake-wifi.log
        fi

        # --- NETWORK MUTATION ---
        for iface in $IFACES; do
            NEW_MAC=$(generate_random_mac)
            NEW_IP=$(generate_random_ip)

            ip link set dev "$iface" down
            ip link set dev "$iface" address "$NEW_MAC"
            ip addr flush dev "$iface"
            ip addr add "$NEW_IP/24" dev "$iface"
            ip link set dev "$iface" up

            echo "[$(date '+%H:%M:%S')] 🔄 $iface updated -> MAC: $NEW_MAC | IP: $NEW_IP" >> /var/log/fake-wifi.log
        done
    done
}

case "$1" in
    start)
        if [ -f "$PID_FILE" ]; then
            echo "⚠️ Fake Wi-Fi is already running!"
            exit 0
        fi

        # 1. Check if Tor package is installed
        if ! command -v tor &> /dev/null; then
            echo "⚠️ Warning: 'tor' package is not installed. Running in local-only mode."
            echo "💡 To enable Tor network proxy support, run: sudo pacman -S tor"
            TOR_ENABLED=false
        else
            TOR_ENABLED=true
        fi
        echo "🚀 Creating fake Wi-Fi devices..."

        if modprobe mac80211_hwsim radios=2; then
            echo "✅ Kernel module mac80211_hwsim loaded."

            # 2. Handle Tor service startup and active connection check
            if [ "$TOR_ENABLED" = true ]; then
                echo "🧅 Starting Tor service..."
                systemctl start tor

                echo "⏳ Establishing Tor circuits (this can take up to 15 seconds)..."
                echo "👉 If it takes too long, press Ctrl+C, or just wait for the timeout."

                # Live test: checking external IP through Tor using icanhazip (more Tor-friendly)
                # Added fake User-Agent to avoid 403 Forbidden errors
                TOR_IP=$(curl -sL -H "User-Agent: Mozilla/5.0" --socks5-hostname 127.0.0.1:9050 --max-time 15 icanhazip.com | tr -d '\r\n ')

                if [ -n "$TOR_IP" ] && [[ ! "$TOR_IP" =~ "html" ]]; then
                    echo "✅ SUCCESS!"
                    echo "🔒 Tor Proxy is ACTIVE on 127.0.0.1:9050"
                    echo "🌍 Your anonymous external Tor IP is: $TOR_IP"
                else
                    echo "❌ VERIFICATION FAILED / TIMEOUT!"
                    echo "⚠️ Tor is running, but the test site blocked the request or circuit is slow."
                    echo "👉 Script will continue. Check '/var/log/fake-wifi.log' later for status."
                fi
            fi

            # Start the rotation daemon process in the background
            rotate_loop >> /var/log/fake-wifi.log 2>&1 &
            echo $! > "$PID_FILE"

            echo "--------------------------------------------------"
            echo "🔄 Rotation daemon started in background (Interval: 20 min)."
            echo "📝 Logs available at: /var/log/fake-wifi.log"
            echo "--------------------------------------------------"
            echo "🎉 System is up, mutating, and monitored!"
        else
            echo "❌ FAILED to load mac80211_hwsim module."
        fi
        ;;

    stop)
        echo "🧹 Removing fake Wi-Fi devices and stopping daemon..."

        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            kill "$PID" &>/dev/null
            rm -f "$PID_FILE"
            echo "✅ Rotation daemon stopped."
        fi

        if systemctl is-active --quiet tor; then
            echo "🧅 Stopping Tor service..."
            systemctl stop tor
        fi

        if modprobe -r mac80211_hwsim &> /dev/null; then
            echo "✅ Module mac80211_hwsim unloaded. Fake devices removed."
        else
            echo "❌ FAILED to remove module. Interfaces might be busy."
        fi
        ;;

    *)
        echo "💻 Usage: sudo fake-wifi-device [start|stop]"
        echo "   Example: sudo fake-wifi-device start"
        exit 1
        ;;
esac
