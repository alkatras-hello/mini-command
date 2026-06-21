#!/bin/bash

# ==============================================================================
# IDEAL PORTKILL UNINSTALLER
# Developed by: alkatras-hello
# ==============================================================================

# 1. Check for root privileges (required to remove files from /usr/local/bin)
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bro, run this uninstaller with sudo: sudo bash uninstall.sh"
    exit 1
fi

echo "🧹 Starting uninstallation..."

# 2. Check if the tool actually exists before deleting
if [ -f "/usr/local/bin/portkill" ]; then
    echo "🗑️  Removing portkill from /usr/local/bin..."
    rm -v "/usr/local/bin/portkill"

    if [ $? -eq 0 ]; then
        echo "------------------------------------------------------"
        echo "✅ SUCCESS! portkill has been completely uninstalled."
        echo "------------------------------------------------------"
    else
        echo "❌ Error: Failed to remove the file."
    fi
else
    echo "ℹ️  Notice: portkill is not found in /usr/local/bin. Nothing to remove."
fi
