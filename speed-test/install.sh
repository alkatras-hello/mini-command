#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "❌ Bro, run with sudo: sudo bash install.sh"
    exit 1
fi

echo "🚀 download command"

# Copy local file and rename it into clean system command
cp "speed-test.sh" "/usr/local/bin/speed-test"

# Set executable permissions
chmod +x "/usr/local/bin/speed-test"

echo "------------------------------------------------------"
echo "🎉 Everything is ready! Your tool pack has been installed."
echo "💻 Now you can simply type in your console:"
echo "   👉 speed-test"
echo "------------------------------------------------------"
