#!/bin/bash

# ==============================================================================
# FAKE-WIFI-DEVICE - Official Uninstaller
# Developed by: alkatras-hello
# ==============================================================================

echo "🧹 Removing Fake-Wifi-Device from your system..."

# Stop the service if it's running before deleting
if [ -f "/usr/local/bin/fake-wifi-device" ]; then
    sudo fake-wifi-device stop &>/dev/null
fi

# Remove the global binary
if [ -f "/usr/local/bin/fake-wifi-device" ]; then
    sudo rm -f /usr/local/bin/fake-wifi-device
    echo "✅ Success: fake-wifi-device command has been removed."
else
    echo "⚠️ Warning: fake-wifi-device command was not found in the system."
fi

echo "=================================================="
echo "✨ Fake-Wifi-Device has been completely uninstalled!"
echo "=================================================="
