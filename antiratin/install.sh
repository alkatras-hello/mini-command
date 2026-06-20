#!/bin/bash

# ==============================================================================
# ANTIRATIN - Official Installer
# Developed by: alkatras-hello
# ==============================================================================

# Ensure the installer is running with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Please run this installer with sudo!"
    exit 1
fi

if [ ! -f "antiratin.sh" ]; then
    echo "❌ Error: antiratin.sh not found in the current directory!"
    exit 1
fi

echo "🚀 Installing Antiratin as a global cybersecurity tool..."

# 1. Copy the main script to system binaries
cp antiratin.sh /usr/local/bin/antiratin
chmod +x /usr/local/bin/antiratin

# 2. Create the shared data directory for databases
mkdir -p /usr/local/share/antiratin

echo "--------------------------------------------------"
echo "✅ Core binary installed successfully!"
echo "🌐 Triggering initial database update..."
echo "--------------------------------------------------"

# 3. Automatically run the first database download
antiratin update

echo "=================================================="
echo "🎉 Done! Command 'antiratin' is now live."
echo "💻 Run it anywhere using sudo:"
echo "   sudo antiratin scan --system"
echo "   sudo antiratin scan --app /path/to/folder"
echo "   sudo antiratin fix"
echo "=================================================="
