#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run with sudo!"
    exit 1
fi

echo "🧹 Removing antivrs"
rm -v /usr/local/bin/antivrs

echo "✅ Uninstalled successfully!"
