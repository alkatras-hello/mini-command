#!/bin/bash

# ==============================================================================
# ANTIRATIN - Official Uninstaller
# Developed by: alkatras-hello
# ==============================================================================

# Ensure the uninstaller is running with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Please run this uninstaller with sudo!"
    exit 1
fi

echo "🧹 Initiating complete removal of Antiratin..."

# 1. Remove the global binary link
if [ -f "/usr/local/bin/antiratin" ]; then
    rm -f /usr/local/bin/antiratin
    echo "✅ Removed: /usr/local/bin/antiratin"
else
    echo "⚠️  Note: Antiratin binary was not found in system paths."
fi

# 2. Wipe out the downloaded tracking signature databases
if [ -d "/usr/local/share/antiratin" ]; then
    rm -rf /usr/local/share/antiratin
    echo "✅ Removed: Local signature database directory (/usr/local/share/antiratin)"
else
    echo "⚠️  Note: Local signature database was already cleared."
fi

echo "================================================--"
echo "✨ Antiratin has been completely uninstalled!"
echo "=================================================="
