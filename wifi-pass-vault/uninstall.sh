#!/bin/bash

# ==============================================================================
# WIFI-PASS-VAULT - Official Uninstaller
# Developed by: alkatras-hello
# ==============================================================================

echo "🧹 Removing Wifi-Pass-Vault from your system..."

# Remove the global binary link
if [ -f "/usr/local/bin/wifi-pass-vault" ]; then
    sudo rm -f /usr/local/bin/wifi-pass-vault
    echo "✅ Success: wifi-pass-vault command has been removed."
else
    echo "⚠️ Warning: wifi-pass-vault command was not found in the system."
fi

echo "=================================================="
echo "✨ Wifi-Pass-Vault has been completely uninstalled!"
echo "=================================================="
