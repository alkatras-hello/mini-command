#!/bin/bash

# ==============================================================================
# STATUS-NET  Uninstaller
# Developed by: alkatras-hello
# ==============================================================================

echo "🧹 Removing Status-Net from your system..."


if [ -f "/usr/local/bin/status_net" ]; then
    sudo rm -f /usr/local/bin/status_net
    echo "✅ Success: status-net command has been removed."
else
    echo "⚠️ Warning: status-net command was not found in the system."
fi

echo "=================================================="
echo "✨ Status-Net has been completely uninstalled!"
echo "=================================================="
