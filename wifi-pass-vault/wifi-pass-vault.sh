#!/bin/bash

# ==============================================================================
# WIFI-PASS-VAULT - Cross-Distribution Wi-Fi Password Extractor
# Developed by: alkatras-hello
# ==============================================================================

# Ensure the script is running with root privileges (sudo)
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This vault is encrypted. Please run with sudo!"
    exit 1
fi

show_help() {
    echo "💻 Usage: sudo wifi-pass-vault [list | search <name> | help]"
    echo "   sudo wifi-pass-vault list          - Show all stored Wi-Fi networks and passwords"
    echo "   sudo wifi-pass-vault search home   - Search for a specific network password"
    exit 0
}

# Header function for clean output
print_header() {
    printf "\n%-30s | %-30s | %-15s\n" "📡 Wi-Fi Network (SSID)" "🔑 Password/Key" "⚙️ Manager"
    echo "---------------------------------------------------------------------------------------"
}

extract_passwords() {
    local search_term=$1
    local found_any=false

    # --- 1. NETWORK MANAGER (Most Common: Arch, Ubuntu, Fedora) ---
    if [ -d "/etc/NetworkManager/system-connections" ]; then
        # Temporary loop through all connection config files
        for file in /etc/NetworkManager/system-connections/*; do
            [ -f "$file" ] || continue

            # Extract SSID and Password from .nmconnection ini-style format
            local ssid=$(grep -E "^ssid=" "$file" | cut -d'=' -f2)
            [ -z "$ssid" ] && ssid=$(grep -E "^id=" "$file" | cut -d'=' -f2) # fallback to id
            local psk=$(grep -E "^psk=" "$file" | cut -d'=' -f2)

            # If it's an open network without a password
            [ -z "$psk" ] && psk="[OPEN NETWORK]"

            # Filter if search term is provided
            if [ -n "$search_term" ]; then
                if [[ ! "${ssid,,}" =~ "${search_term,,}" ]]; then
                    continue
                fi
            fi

            if [ "$found_any" = false ]; then print_header; found_any=true; fi
            printf "%-30s | %-30s | %-15s\n" "$ssid" "$psk" "NetworkManager"
        done
    fi

    # --- 2. WPA_SUPPLICANT (Debian/Server setups) ---
    if [ -f "/etc/wpa_supplicant/wpa_supplicant.conf" ]; then
        # Parse blocks of network={ ... }
        # Using awk to extract ssid and psk values cleanly
        local wpa_data=$(awk '
            /network=\{/,/\}/ {
                if ($1 ~ /ssid=/) { gsub(/ssid=|"/, ""); ssid=$0 }
                if ($1 ~ /psk=/) { gsub(/psk=|"/, ""); psk=$0 }
                if ($1 ~ /\}/) {
                    if (ssid) {
                        if (!psk) psk="[OPEN NETWORK]"
                        print ssid "::" psk
                    }
                    ssid=""; psk=""
                }
            }
        ' /etc/wpa_supplicant/wpa_supplicant.conf)

        if [ -n "$wpa_data" ]; then
            while IFS="::" read -r ssid psk; do
                [ -z "$ssid" ] && continue

                if [ -n "$search_term" ]; then
                    if [[ ! "${ssid,,}" =~ "${search_term,,}" ]]; then
                        continue
                    fi
                fi

                if [ "$found_any" = false ]; then print_header; found_any=true; fi
                printf "%-30s | %-30s | %-15s\n" "$ssid" "$psk" "wpa_supplicant"
            done <<< "$wpa_data"
        fi
    fi

    # --- 3. iWD (Modern Intel Wireless Daemon) ---
    if [ -d "/var/lib/iwd" ]; then
        for file in /var/lib/iwd/*.{psk,8021x}; do
            [ -f "$file" ] || continue

            local filename=$(basename "$file")
            local ssid="${filename%.*}" # strip extension to get SSID
            local psk=$(grep -E "^PreSharedKey=" "$file" | cut -d'=' -f2)

            [ -z "$psk" ] && psk="[802.1X Enterprise]"
            if [ -n "$search_term" ]; then
                if [[ ! "${ssid,,}" =~ "${search_term,,}" ]]; then
                    continue
                fi
            fi

            if [ "$found_any" = false ]; then print_header; found_any=true; fi
            printf "%-30s | %-30s | %-15s\n" "$ssid" "$psk" "iWD"
        done
    fi

    if [ "$found_any" = false ]; then
        if [ -n "$search_term" ]; then
            echo "🔍 No Wi-Fi password found matching: '$search_term'"
        else
            echo "⚠️ No stored Wi-Fi connections discovered on this system."
        fi
    fi
    echo ""
}

# Command routing
case "$1" in
    list)
        echo "🔓 Accessing secure Wi-Fi database..."
        extract_passwords
        ;;
    search)
        if [ -z "$2" ]; then
            echo "❌ Error: Please specify a network name to search for!"
            echo "👉 Example: sudo wifi-pass-vault search Home_WiFi"
            exit 1
        fi
        echo "🔍 Searching secure Wi-Fi database for '$2'..."
        extract_passwords "$2"
        ;;
    help|*)
        show_help
        ;;
esac
