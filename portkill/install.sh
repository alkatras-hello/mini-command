#!/bin/bash


# 1. Check for root privileges (required to write into /usr/local/bin)
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bro, run this installer with sudo: sudo bash install.sh"
    exit 1
fi

echo "🚀 Starting installation..."

echo "dowanload portkill"
cp "portkill.sh" "/usr/local/bin/portkill"


chmod +x "/usr/local/bin/portkill"

echo "------------------------------------------------------"
echo "🎉 SUCCESS! portkill has been successfully installed!"
echo "💻 You can now use it from anywhere by typing: portkill"
echo "------------------------------------------------------"
