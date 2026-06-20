#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "❌ Bro, run with sudo: sudo bash install.sh"
    exit 1
fi

echo "🚀 dowanload command"

# Copy local files and rename them into clean system commands
cp "antivrs.sh" "/usr/local/bin/antivrs"


# Set executable permissions
chmod +x "/usr/local/bin/antivrs"


echo "------------------------------------------------------"
echo "🎉 Everything is ready! Your tool pack has been installed."
echo "💻 Now you can simply type in your console:"
echo "   👉 antivrs <file>"
echo "------------------------------------------------------"
