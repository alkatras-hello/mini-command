#!/bin/bash

# ==============================================================================
# FAKE-WIFI-DEVICE - Virtual Wi-Fi Simulator with MAC/IP Rotation & Tor Proxy
# Developed by: alkatras-hello
#
# HARD REGENERATION MODE ACTIVE - Wiping kernel modules on each cycle to beat WIPS
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
    echo "[$(date '+%H:%M:%S')] 🚀 Fake Wi-Fi daemon successfully started!" >> /var/log/fake-wifi.log
    echo "[$(date '+%H:%M:%S')] ⏳ Hard regeneration cycle: 20 minutes interval..." >> /var/log/fake-wifi.log

    while true; do
        # 20 хвилин сну (1200 секунд) перед жорстким релоадом модуля
        sleep 1200

        MSG="⚠️ Attention! HARD REGENERATION of kernel interfaces and wireless devices NOW..."
        echo "[$(date '+%H:%M:%S')] $MSG" >> /var/log/fake-wifi.log

        # Звукові сигнали в TTY
        printf "\a" > /dev/tty1 2>/dev/null
        printf "\a" > /dev/tty3 2>/dev/null

        # Надсилання сповіщення на робочий стіл поточного користувача
        CURRENT_USER=$(who | awk '{print $1}' | head -n1)
        USER_ID=$(id -u "$CURRENT_USER")
        DBUS_LAUNCH="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus"
        sudo -u "$CURRENT_USER" $DBUS_LAUNCH notify-send "Fake Wi-Fi & Tor" "$MSG" &>/dev/null

        # Оновлюємо ланцюжок Tor, якщо сервіс активний
        if systemctl is-active --quiet tor; then
            systemctl reload tor &>/dev/null
            echo "[$(date '+%H:%M:%S')] 🧅 Tor identity refreshed (New external WAN IP requested)." >> /var/log/fake-wifi.log
        fi

        # -----------------------------------------------------------------
        # КРОК 1: ЖОРСТКЕ ЗНЕСЕННЯ СТАРИХ ІНТЕРФЕЙСІВ З ЯДРА (Нищимо старі ID)
        # -----------------------------------------------------------------
        echo "[$(date '+%H:%M:%S')] 🧹 Unloading mac80211_hwsim to wipe previous system IDs..." >> /var/log/fake-wifi.log
        modprobe -r mac80211_hwsim &>/dev/null
        sleep 2

        # -----------------------------------------------------------------
        # КРОК 2: ПОВНЕ ПЕРЕРОДЖЕННЯ (Створення абсолютно нових карт)
        # -----------------------------------------------------------------
        echo "[$(date '+%H:%M:%S')] 🧬 Loading fresh module with 4 new hardware structures..." >> /var/log/fake-wifi.log
        if ! modprobe mac80211_hwsim radios=4; then
            echo "[$(date '+%H:%M:%S')] ❌ FAILED to reload kernel module! Waiting for next cycle..." >> /var/log/fake-wifi.log
            continue
        fi
        sleep 2

        # Зчитуємо щойно створені інтерфейси, бо їхні внутрішні індекси в ядрі змінилися!
        IFACES=$(ip link show | grep -o -E "wlan[0-9]+")


        # -----------------------------------------------------------------
        # КРОК 3: НАЛАШТУВАННЯ НОВИХ МУТАЦІЙ ТА ШУМУ
        # -----------------------------------------------------------------
        for iface in $IFACES; do
            NEW_MAC=$(generate_random_mac)
            NEW_IP=$(generate_random_ip)
            NEW_HOST=$(generate_random_hostname)

            # Ініціалізуємо свіжу карту на низькому рівні
            ip link set dev "$iface" down
            ip link set dev "$iface" address "$NEW_MAC"
            ip addr flush dev "$iface" &>/dev/null
            ip addr add "$NEW_IP/24" dev "$iface"

            # Маскування ізоляції запитів
            sysctl -w net.ipv4.conf."$iface".arp_ignore=1 &>/dev/null
            ip link set dev "$iface" up

            # Емулюємо життєдіяльність пристрою для генерації фонового шуму
            generate_noise_traffic "$iface"

            echo "[$(date '+%H:%M:%S')] ✨ New Hardware Node $iface -> MAC: $NEW_MAC | IP: $NEW_IP | Host: $NEW_HOST" >> /var/log/fake-wifi.log
        done
        echo "[$(date '+%H:%M:%S')] ⏳ Next hard regeneration in 20 minutes..." >> /var/log/fake-wifi.log
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

        # Первинне завантаження 4 віртуальних радіо-інтерфейсів
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

            # Запускаємо безкінечний цикл жорсткої регенерації у фоні
            rotate_loop >> /var/log/fake-wifi.log 2>&1 &
            echo $! > "$PID_FILE"

            echo "--------------------------------------------------"
            echo "🔄 Hard Regeneration daemon started (Interval: 20 min)."
            echo "📝 Watch real-time changes: tail -f /var/log/fake-wifi.log"
            echo "--------------------------------------------------"
            echo "🎉 PRIVACY COMPLIANCE: 4 Hardware nodes are ready to morph!"
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
