#!/bin/bash

# ==============================================================================
# STATUS-NET - Official Installer
# Developed by: alkatras-hello
# ==============================================================================

# Check if the status-net script exists in the folder
if [ ! -f "status_net.sh" ]; then
    echo "❌ Error: status-net.sh not found in this directory!"
    echo "Make sure you are running install-net.sh from the correct folder."
    exit 1
fi

echo "🚀 Installing Status-Net as a global system command..."

# Copy to the system bin folder under the command name status-net
sudo cp status_net.sh /usr/local/bin/status_net

# Give execution permissions
sudo chmod 755 /usr/local/bin/status_net

echo "=================================================="
echo "🎉 Done! Status_Net installed successfully."
echo "💻 Use it anywhere in your terminal like this:"
echo "   status-net"
echo "=================================================="
