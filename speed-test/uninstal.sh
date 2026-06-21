#!/bin/bash
# ========================================================
# Developed by: alkatras-hello
# Project: mini-command
# Description: Automatic uninstaller for speed-test tool
# ========================================================

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run with sudo!"
    exit 1
fi

echo "🧹 Removing speed-test"
rm -v /usr/local/bin/speed-test

echo "✅ Uninstalled successfully!"
