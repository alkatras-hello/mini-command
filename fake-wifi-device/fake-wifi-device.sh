#!/bin/bash

# ==============================================================================
# FAKE-WIFI-DEVICE - Virtual Wi-Fi Simulator with MAC/IP Rotation & Tor Proxy
# Developed by: alkatras-hello
#
# MODES:
#  1. default -  Зміна MAC раз на 60 хв.
#  2. angry   - Повне знесення модулів ядра кожні 20 хв.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Please run this script with sudo!"
    exit 1
fi

PID_FILE="/var/run/fake_wifi_rotate.pid"
MODE_FILE="/var/run/fake_wifi_mode.txt"

# --- ГЕНЕРАТОРЫ МАСКУВАННЯ ---
generate_random_mac() {
    PREFIXES=("00:25:00" "00:0a:95" "44:61:32" "78:4f:43" "bc:d0:74" "00:16:ea")
    RAND_PREFIX=${PREFIXES[$((RANDOM % ${#PREFIXES[@]}))]}
    printf '%s:%02x:%02x:%02x\n' "$RAND_PREFIX" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

generate_random_hostname() {
    NAMES=("Redmi-Note-14" "Redmi-Note-13" "iPhone-15" "Galaxy-S24" "iPad-Air" "Pixel-8" "MacBook-Pro" "Nintendo-Switch")
    echo "${NAMES[$((RANDOM % ${#NAMES[@]}))]}-$((RANDOM%900 + 100))"
}

generate_random_ip() {
    echo "192.168.$((RANDOM%254 + 1)).$((RANDOM%254 + 1))"
}

generate_noise_traffic() {
    local iface=$1
    DOMAINS=("apple.com" "google.com" "connectivitycheck.gstatic.com" "microsoft.com")
    RAND_DOMAIN=${DOMAINS[$((RANDOM % ${#DOMAINS[@]}))]}
    ping -I "$iface" -c 2 "$RAND_DOMAIN" &>/dev/null &
}

# --- ОСНОВНИЙ ЦИКЛ РОТАЦІЇ ---
rotate_loop() {
    local RUN_MODE=$(cat "$MODE_FILE" 2>/dev/null)
    [ -z "$RUN_MODE" ] && RUN_MODE="default"

    echo "[$(date '+%H:%M:%S')] 🚀 Fake Wi-Fi daemon successfully started in [$RUN_MODE] mode!" >> /var/log/fake-wifi.log

    if [ "$RUN_MODE" = "angry" ]; then
        echo "[$(date '+%H:%M:%S')] ⏳ Angry mode active: 20 minutes interval with hard hardware reset." >> /var/log/fake-wifi.log
    else
        echo "[$(date '+%H:%M:%S')] ⏳ Default mode active: 60 minutes interval (Stealth background rotation)." >> /var/log/fake-wifi.log
    fi

    while true; do
        if [ "$RUN_MODE" = "angry" ]; then
            sleep 1200 # 20 хвилин для Лютого (Angry) режиму
        else
            sleep 3600 # 60 хвилин для Спокійного (Default) режиму
        fi

        MSG="⚠️ Attention! Network rotation triggered in [$RUN_MODE] mode..."
        echo "[$(date '+%H:%M:%S')] $MSG" >> /var/log/fake-wifi.log

        printf "\a" > /dev/tty1 2>/dev/null
        printf "\a" > /dev/tty3 2>/dev/null

        CURRENT_USER=$(who | awk '{print $1}' | head -n1)
        USER_ID=$(id -u "$CURRENT_USER")
        DBUS_LAUNCH="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus"
        sudo -u "$CURRENT_USER" $DBUS_LAUNCH notify-send "Fake Wi-Fi & Tor" "$MSG" &>/dev/null

        if systemctl is-active --quiet tor; then
            systemctl reload tor &>/dev/null
            echo "[$(date '+%H:%M:%S')] 🧅 Tor identity refreshed." >> /var/log/fake-wifi.log
        fi

        if [ "$RUN_MODE" = "angry" ]; then
            echo "[$(date '+%H:%M:%S')] 🧹 [ANGRY] Unloading mac80211_hwsim to wipe system IDs..." >> /var/log/fake-wifi.log
            modprobe -r mac80211_hwsim &>/dev/null
            sleep 2

            echo "[$(date '+%H:%M:%S')] 🧬 [ANGRY] Re-loading fresh module with 4 radios..." >> /var/log/fake-wifi.log
            if ! modprobe mac80211_hwsim radios=4; then
                echo "[$(date '+%H:%M:%S')] ❌ FAILED to reload kernel module!" >> /var/log/fake-wifi.log
                continue
            fi
            sleep 2
        fi

        IFACES=$(ip link show | grep -o -E "wlan[0-9]+")

        for iface in $IFACES; do
            NEW_MAC=$(generate_random_mac)
            NEW_IP=$(generate_random_ip)
            NEW_HOST=$(generate_random_hostname)

            ip link set dev "$iface" down
            ip link set dev "$iface" address "$NEW_MAC"
            ip addr flush dev "$iface" &>/dev/null
            ip addr add "$NEW_IP/24" dev "$iface"


            sysctl -w net.ipv4.conf."$iface".arp_ignore=1 &>/dev/null
            ip link set dev "$iface" up

            generate_noise_traffic "$iface"

            echo "[$(date '+%H:%M:%S')] ✨ Node $iface morphed -> MAC: $NEW_MAC | IP: $NEW_IP | Host: $NEW_HOST" >> /var/log/fake-wifi.log
        done
    done
}

case "$1" in
    start)
        if [ -f "$PID_FILE" ]; then
            echo "⚠️ Fake Wi-Fi is already running!"
            exit 0
        fi

        CHOSEN_MODE="$2"

        # Перевірка на відсутність аргументу або помилку вводу
        if [ "$CHOSEN_MODE" != "default" ] && [ "$CHOSEN_MODE" != "angry" ]; then
            echo "--------------------------------------------------"
            echo "⚙️  Fake Wi-Fi Device - selecting an Operating Mode :"
            echo "--------------------------------------------------"
            echo "1) default - Change the Mac and IP addresses every 60 minutes "
            echo "2) angry   - Complete reset of cards and new IDs every 20 minutes"
            echo "--------------------------------------------------"
            read -p " 1 or 2: " MODE_CHOICE

            case "$MODE_CHOICE" in
                1|default)
                    CHOSEN_MODE="default"
                    ;;
                2|angry)
                    CHOSEN_MODE="angry"
                    ;;
                *)
                    echo "❌ Error: Incorrect selection. Safe mode is automatically enabled [default]."
                    CHOSEN_MODE="default"
                    ;;
            esac
        fi

        echo "$CHOSEN_MODE" > "$MODE_FILE"

        if ! command -v tor &> /dev/null; then
            TOR_ENABLED=false
        else
            TOR_ENABLED=true
        fi

        echo "🚀 Initializing virtual Wi-Fi infrastructure in [$CHOSEN_MODE] mode..."

        if modprobe mac80211_hwsim radios=4; then
            echo "✅ Kernel module mac80211_hwsim loaded with 4 virtual radios."

            if [ "$TOR_ENABLED" = true ]; then
                systemctl start tor
                TOR_IP=$(curl -sL -H "User-Agent: Mozilla/5.0" --socks5-hostname 127.0.0.1:9050 --max-time 15 icanhazip.com | tr -d '\r\n ')
                [ -n "$TOR_IP" ] && [[ ! "$TOR_IP" =~ "html" ]] && echo "✅ Tor Proxy ACTIVE. IP: $TOR_IP"
            fi

            rotate_loop >> /var/log/fake-wifi.log 2>&1 &
            echo $! > "$PID_FILE"

            echo "--------------------------------------------------"
            echo "🔄 Rotation daemon started in background (Mode: $CHOSEN_MODE)."
            echo "📝 Logs available at: tail -f /var/log/fake-wifi.log"
            echo "--------------------------------------------------"
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
            rm -f "$MODE_FILE"
            echo "✅ Rotation daemon stopped."
        fi

        if systemctl is-active --quiet tor; then
            systemctl stop tor
        fi

        modprobe -r mac80211_hwsim &> /dev/null
        echo "✅ Module unloaded. Fake devices removed."
        ;;

    *)
        echo "💻 Usage: sudo fake-wifi-device.sh [start|stop] [default|angry]"
        exit 1
        ;;
esac
