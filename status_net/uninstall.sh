#!/bin/bash

# ==============================================================================
# STATUS-NET - Official Uninstaller
# Developed by: alkatras-hello
# ==============================================================================

echo "🧹 Removing Status-Net from your system..."

# Перевіряємо, чи є такий файл у системі, і зносимо його
if [ -f "/usr/local/bin/status_net" ]; then
    sudo rm -f /usr/local/bin/status_net
    echo "✅ Success: status-net command has been removed."
else
    echo "⚠️ Warning: status-net command was not found in the system."
fi

echo "=================================================="
echo "✨ Status-Net has been completely uninstalled!"
echo "=================================================="
