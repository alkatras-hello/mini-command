#!/bin/bash

# ==============================================================================
# PORTKILL v1.2 - Universal IPv4/IPv6 Network Port Process Terminator
# Developed by: alkatras-hello
# ==============================================================================

PORT=$1

# 1. If no port was passed as an argument, ask the user interactively
if [ -z "$PORT" ]; then
    read -p "🔌 Enter the port number you want to free: " PORT
fi

# Validate that input is actually a number
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Port must be a valid number!"
    exit 1
fi

# 2. Find PID running on the specified port (Universal TCP check for IPv4 and IPv6)
PID=$(lsof -t -i tcp:"$PORT")

if [ -z "$PID" ]; then
    echo "ℹ️  No process found running on port $PORT."
    echo "💡 [Tip] If the server was started by another user or root, try: sudo portkill $PORT"
    exit 0
fi

# Get the process name for better clarity
PROCESS_NAME=$(ps -p $PID -o comm= 2>/dev/null)
echo "🔍 Found process '${PROCESS_NAME:-Unknown}' (PID: $PID) occupying port $PORT."

# 3. Double-check with the user before killing it
read -p "⚠️  Are you sure you want to terminate this process? (y/n): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "💥 Terminating process..."
    kill -9 $PID 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Success! Port $PORT is now completely free."
    else
        echo "❌ Error: Failed to kill process. You probably need root privileges!"
        echo "👉 Try running: sudo portkill $PORT"
    fi
else
    echo "🛡️  Operation canceled. Process left alive."
fi
