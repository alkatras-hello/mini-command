#!/bin/bash

# ==============================================================================
# WIFI-PASS-VAULT - Official Installer
# Developed by: alkatras-hello
# ==============================================================================

if [ ! -f "wifi-pass-vault.sh" ]; then
    echo "❌ Error: wifi-pass-vault.sh not found!"
    exit 1
fi

echo "🚀 Installing Wifi-Pass-Vault as a cross-distro system command..."

sudo cp wifi-pass-vault.sh /usr/local/bin/wifi-pass-vault
sudo chmod +x /usr/local/bin/wifi-pass-vault

echo "=================================================="
echo "🎉 Done! Command 'wifi-pass-vault' is now available."
echo "💻 Run it anywhere with sudo:"
echo "   sudo wifi-pass-vault list"
echo "   sudo wifi-pass-vault search <network_name>"
echo "=================================================="
