#!/bin/bash

# ==============================================================================
# PACKAGE#PRESS - Official Uninstaller
# Developed by: alkatras-hello
# ==============================================================================

echo "🧹 Uninstalling Package#Press from your system..."

# Check if the command exists before deleting
if [ -f "/usr/local/bin/pkg-press" ]; then
    # Remove the system command
    sudo rm -f /usr/local/bin/pkg-press
    echo "✅ Success: pkg-press command has been removed."
else
    echo "⚠️ Warning: pkg-press command was not found in the system."
fi

echo "=================================================="
echo "✨ Package#Press has been completely uninstalled!"
echo "=================================================="
