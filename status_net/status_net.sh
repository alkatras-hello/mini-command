#!/bin/bash

# ==============================================================================
# STATUS-NET - Network Diagnostics & Router Port Scanner (With Manual IP Prompt)
# Developed by: alkatras-hello
# ==============================================================================

echo "🔍 Starting Network Diagnostics... Please wait..."
echo "--------------------------------------------------"

# --- 1. CHECK LOCAL INTERFACE ---
echo -n "🌐 Checking local network interfaces... "
if ip link show | grep -q "LOWER_UP"; then
    echo "✅ OK (Interface is UP)"
else
    echo "❌ FAILED (All network interfaces are DOWN or disconnected!)"
    exit 1
fi

# --- 2. FIND AND PROMPT FOR GATEWAY IP ---
# Автоматично шукаємо дефолтний шлюз для підказки
AUTO_GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n 1)

echo "--------------------------------------------------"
# Питаємо IP роутера у користувача
read -p "❓ What IP wifi (Press Enter for default $AUTO_GATEWAY): " IP_INET

# Якщо юзер нічого не ввів і просто натиснув Enter — беремо авто-IP
if [ -z "$IP_INET" ]; then
    IP_INET="$AUTO_GATEWAY"
fi

# Якщо і авто-IP порожній, і юзер нічого не ввів — видаємо помилку
if [ -z "$IP_INET" ]; then
    echo "❌ FAILED (No IP address provided and default gateway not found!)"
    exit 1
fi
echo "--------------------------------------------------"

# --- 3. CHECK GATEWAY (ROUTER) ---
echo -n "📟 Pinging local gateway ($IP_INET)... "
if ping -c 1 -W 2 "$IP_INET" &> /dev/null; then
    echo "✅ OK (Connected to router: $IP_INET)"
else
    echo "❌ FAILED (Router $IP_INET is not responding!)"
fi

# --- 4. CHECK INTERNET ACCESS (RAW IP) ---
echo -n "🌍 Testing internet connection (Ping 1.1.1.1)... "
if ping -c 1 -W 2 1.1.1.1 &> /dev/null; then
    echo "✅ OK (External WAN access is available)"
else
    echo "❌ FAILED (Cannot reach global network. ISP issue?)"
fi

# --- 5. CHECK DNS RESOLUTION ---
echo -n "🔮 Testing DNS resolution (Resolving google.com)... "
if host google.com &> /dev/null || ping -c 1 -W 2 google.com &> /dev/null; then
    echo "✅ OK (DNS is working properly)"
else
    echo "❌ FAILED (DNS failure! Cannot resolve domain names)"
fi

echo "--------------------------------------------------"
echo "🎉 Diagnostics complete!"
echo "--------------------------------------------------"

# --- 6. ROUTER PORT SCANNER ---
echo "🛡️ Scanning common ports on your router ($IP_INET)..."

# Список стандартних портів для перевірки
PORTS=(22 23 53 80 443 8080)
# Зручні назви для портів
declare -A PORT_NAMES=( [22]="SSH" [23]="Telnet" [53]="DNS" [80]="HTTP (Web UI)" [443]="HTTPS (Secure Web UI)" [8080]="Alternative Web UI" )

for port in "${PORTS[@]}"; do
    # Стукаємо в порт через вбудований TCP-девайс Bash з таймаутом в 1 секунду
    if timeout 1 bash -c "cat < /dev/null > /dev/tcp/$IP_INET/$port" &> /dev/null; then
        echo "   🔓 Port $port [${PORT_NAMES[$port]}]: OPEN"
    else
        echo "   🔒 Port $port [${PORT_NAMES[$port]}]: CLOSED"
    fi
done
echo "--------------------------------------------------"
