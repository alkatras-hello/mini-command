#!/bin/bash

# ==============================================================================
# FAKE-WIFI-DEVICE - Official Installer
# Developed by: alkatras-hello
# ==============================================================================

# Check if the script exists in the current folder
if [ ! -f "fake-wifi-device.sh" ]; then
    echo "❌ Error: fake-wifi-device.sh not found in this directory!"
    echo "Make sure you are running install-fake.sh from the correct folder."
    exit 1
fi

echo "🚀 Installing Fake-Wifi-Device as a global system command..."

# Copy to the system bin folder under the clean command name
sudo cp fake-wifi-device.sh /usr/local/bin/fake-wifi-device

# Give execution privileges
sudo chmod +x /usr/local/bin/fake-wifi-device

echo "=================================================="
echo "🎉 Done! Fake-Wifi-Device installed successfully."
echo "💻 You can now use it anywhere via sudo:"
echo "   sudo fake-wifi-device start"
echo "   sudo fake-wifi-device stop"
echo "=================================================="
