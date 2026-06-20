#!/bin/bash

# ==============================================================================
# PACKAGE#PRESS - Official Installer
# Developed by: alkatras-hello
# ==============================================================================

# Check if the main script exists in the folder
if [ ! -f "pkg-press.sh" ]; then
    echo "❌ Error: pkg-press.sh not found in this directory!"
    echo "Make sure you are running install.sh from the correct folder."
    exit 1
fi

echo "🚀 Installing Package#Press as a global system command..."

# Copy to the system bin folder
sudo cp pkg-press.sh /usr/local/bin/pkg-press

# Give execution permissions
sudo chmod +x /usr/local/bin/pkg-press

echo "=================================================="
echo "🎉 Done! Package#Press installed successfully."
echo "💻 Use it anywhere in your terminal like this:"
echo "   pkg-press c f filename.txt"
echo "=================================================="
