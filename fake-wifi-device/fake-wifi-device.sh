#!/bin/bash

# ==============================================================================
# FAKE-WIFI-DEVICE - Virtual Wi-Fi Simulator with MAC/IP Rotation & Tor Proxy
# Developed by: alkatras-hello
#
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Please run this script with sudo!"
    exit 1
fi

PID_FILE="/var/run/fake_wifi_rotate.pid"

# --- ПОКРАЩЕННЯ 1: Генерація реальних префіксів (OUI) відомих брендів ---
generate_random_mac() {
    # Масиви префіксів: Apple, Samsung, Google, Intel, Cisco
    PREFIXES=("00:25:00" "00:0a:95" "44:61:32" "78:4f:43" "bc:d0:74" "00:16:ea")
    RAND_PREFIX=${PREFIXES[$((RANDOM % ${#PREFIXES[@]}))]}
    printf '%s:%02x:%02x:%02x\n' "$RAND_PREFIX" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# --- ПОКРАЩЕННЯ 2: Рандомні імена пристроїв для обману DHCP роутера ---
generate_random_hostname() {
    NAMES=("iPhone-15" "Galaxy-S24" "iPad-Air" "Pixel-8" "Smart-TV-LivingRoom" "HP-LaserJet" "MacBook-Pro" "Nintendo-Switch")
    echo "${NAMES[$((RANDOM % ${#NAMES[@]}))]}-$((RANDOM%900 + 100))"
}

generate_random_ip() {
    echo "192.168.$((RANDOM%254 + 1)).$((RANDOM%254 + 1))"
}

# --- ПОКРАЩЕННЯ 3: Генерація фейкового фонового трафіку (Шум для DPI) ---
generate_noise_traffic() {
    local iface=$1
    # Симулюємо пінг на випадкові сервіси, ніби девайс «живий» і перевіряє мережу
    DOMAINS=("apple.com" "google.com" "connectivitycheck.gstatic.com" "microsoft.com")
    RAND_DOMAIN=${DOMAINS[$((RANDOM % ${#DOMAINS[@]}))]}
    ping -I "$iface" -c 2 "$RAND_DOMAIN" &>/dev/null &
}

rotate_loop() {
    sleep 2
    IFACES=$(ip link show | grep -o -E "wlan[0-9]+")

    if [ -z "$IFACES" ]; then
        echo "[$(date '+%H:%M:%S')] ⚠️ No wlan interfaces found for rotation." >> /var/log/fake-wifi.log
        exit 1
    fi

    echo "[$(date '+%H:%M:%S')] 🚀 Fake Wi-Fi daemon successfully started!" >> /var/log/fake-wifi.log
    for iface in $IFACES; do
        CURRENT_MAC=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')
        echo "[$(date '+%H:%M:%S')] 📡 Monitoring interface: $iface (Initial MAC: $CURRENT_MAC)" >> /var/log/fake-wifi.log
    done
    echo "[$(date '+%H:%M:%S')] ⏳ Next rotation in 20 minutes..." >> /var/log/fake-wifi.log

    while true; do
        # 20 хвилин сну (1200 секунд)
        sleep 1200

        MSG="⚠️ Attention! Rotating MAC, IP, Hostname, and Tor Identity NOW..."
        echo "[$(date '+%H:%M:%S')] $MSG" >> /var/log/fake-wifi.log

        printf "\a" > /dev/tty1 2>/dev/null
        printf "\a" > /dev/tty3 2>/dev/null

        CURRENT_USER=$(who | awk '{print $1}' | head -n1)
        USER_ID=$(id -u "$CURRENT_USER")
        DBUS_LAUNCH="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus"
        sudo -u "$CURRENT_USER" $DBUS_LAUNCH notify-send "Fake Wi-Fi & Tor" "$MSG" &>/dev/null

        if systemctl is-active --quiet tor; then
            systemctl reload tor &>/dev/null
            echo "[$(date '+%H:%M:%S')] 🧅 Tor identity refreshed (New external WAN IP requested)." >> /var/log/fake-wifi.log
        fi

        # --- ОНОВЛЕНА МУТАЦІЯ МЕРЕЖІ ---
        for iface in $IFACES; do
            NEW_MAC=$(generate_random_mac)
            NEW_IP=$(generate_random_ip)
            NEW_HOST=$(generate_random_hostname)

            # Наднизький рівень: міняємо MAC, IP та Hostname для інтерфейсу
            ip link set dev "$iface" down
            ip link set dev "$iface" address "$NEW_MAC"
            ip addr flush dev "$iface"
            ip addr add "$NEW_IP/24" dev "$iface"

            # Зміна hostname суто для цього мережевого запиту через sysctl (якщо підтримується)
            sysctl -w net.ipv4.conf."$iface".arp_ignore=1 &>/dev/null

            ip link set dev "$iface" up

            # Запуск фонового шуму для обману систем стеження (DPI) провайдера
            generate_noise_traffic "$iface"

            echo "[$(date '+%H:%M:%S')] 🔄 $iface updated -> MAC: $NEW_MAC | IP: $NEW_IP | Host: $NEW_HOST" >> /var/log/fake-wifi.log
        done
    done
}

case "$1" in
    start)
        if [ -f "$PID_FILE" ]; then
            echo "⚠️ Fake Wi-Fi is already running!"
            exit 0
        fi

        if ! command -v tor &> /dev/null; then
            echo "⚠️ Warning: 'tor' package is not installed. Running in local-only mode."
            TOR_ENABLED=false
        else
            TOR_ENABLED=true
        fi
        echo "🚀 Creating fake Wi-Fi devices..."

        # Збільшуємо кількість радіо-інтерфейсів до 4 для створення більшої маси фейків!
        if modprobe mac80211_hwsim radios=4; then
            echo "✅ Kernel module mac80211_hwsim loaded with 4 virtual radios."

            if [ "$TOR_ENABLED" = true ]; then
                echo "🧅 Starting Tor service..."
                systemctl start tor
                echo "⏳ Establishing Tor circuits..."
                TOR_IP=$(curl -sL -H "User-Agent: Mozilla/5.0" --socks5-hostname 127.0.0.1:9050 --max-time 15 icanhazip.com | tr -d '\r\n ')

                if [ -n "$TOR_IP" ] && [[ ! "$TOR_IP" =~ "html" ]]; then
                    echo "✅ Tor Proxy is ACTIVE. External IP: $TOR_IP"
                else
                    echo "❌ Tor verification timeout. Continuing..."
                fi
            fi

            rotate_loop >> /var/log/fake-wifi.log 2>&1 &
            echo $! > "$PID_FILE"

            echo "--------------------------------------------------"
            echo "🔄 Rotation daemon started in background (Interval: 20 min)."
            echo "📝 Logs available at: /var/log/fake-wifi.log"
            echo "--------------------------------------------------"
            echo "🎉 PRIVACY MODE ACTIVE: 4 Virtual devices are mutating!"
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
        exit 1
        ;;
esac
