#!/bin/bash

# ==============================================================================
# ANTIRATIN v2.0 - Advanced Dynamic Telemetry Scanner & App Auditor
# Developed by: alkatras-hello
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Antiratin requires root privileges. Run with sudo!"
    exit 1
fi

# Local storage for dynamic databases
DATA_DIR="/usr/local/share/antiratin"
HOSTS_DB="$DATA_DIR/spy_hosts.txt"
PROCS_DB="$DATA_DIR/spy_procs.txt"

# Fallback lists if internet is down during first run
DEFAULT_HOSTS=("telemetry.mozilla.org" "metrics.discordapp.net" "telemetry.discordapp.net" "vortex.data.microsoft.com")
DEFAULT_PROCS=("discord" "spotify" "steam" "chrome" "teamviewer")

show_help() {
    echo "💻 Usage: sudo antiratin [command] [options]"
    echo "----------------------------------------------------------------"
    echo "⚙️  Core Commands:"
    echo "   sudo antiratin update          - Download latest rat-lists from database"
    echo "   sudo antiratin scan --system   - Deep scan entire OS and services"
    echo "   sudo antiratin scan --app <dir>- Audit specific app folder for telemetry tracking"
    echo "   sudo antiratin fix             - Block all found system rats and domains"
    echo "----------------------------------------------------------------"
    exit 0
}

# Ensure local folder exists
mkdir -p "$DATA_DIR"

# --- DATABASE UPDATE FUNCTION (LIVE INTERNET FETCH) ---
update_db() {
    echo "🌐 Fetching live spy/telemetry signatures from global blocklists..."

    # Temporary files for raw download
    local tmp_hosts=$(mktemp)

    # URL 1: Official AdAway telemetry & spyware hosts blocklist
    echo "📥 Downloading telemetry domains from AdAway open-source database..."
    curl -sL --max-time 15 "https://adaway.org/hosts.txt" -o "$tmp_hosts"

    # Verify if the download was successful and has actual data
    if [ -s "$tmp_hosts" ] && ! grep -q "404" "$tmp_hosts"; then
        # Clean the hosts file: extract only domain names, remove 127.0.0.1, comments, and empty lines
        awk '/^127\.0\.0\.1/ {print $2}' "$tmp_hosts" | grep -vE "(localhost|ip6-)" | sort -u > "$HOSTS_DB"
        echo "✅ Success: Dynamic hosts database created with $(wc -l < "$HOSTS_DB") telemetry domains!"
        rm -f "$tmp_hosts"
    else
        echo "⚠️  Failed to fetch live hosts list. Deploying default secure fallback..."
        printf "%s\n" "${DEFAULT_HOSTS[@]}" > "$HOSTS_DB"
        rm -f "$tmp_hosts"
    fi

    # Generate a solid dynamic list of spy-processes to monitor
    echo "📝 Generating active spy-process tracking signatures..."
    {
        printf "%s\n" "${DEFAULT_PROCS[@]}"
        echo "chrome"
        echo "chromium"
        echo "opera"
        echo "viber"
        echo "telegram-desktop"
        echo "anydesk"
        echo "teamviewer"
        echo "code" # VS Code telemetry
        echo "webcord"
    } | sort -u > "$PROCS_DB"
    echo "✅ Success: Process tracker loaded with $(wc -l < "$PROCS_DB") known tracking apps."
}

# --- MODE 1: GLOBAL SYSTEM SCAN ---
scan_system() {
    echo "🔍 [ANTIRATIN] Running full system audit..."
    echo "----------------------------------------------------------------"
    [ -f "$PROCS_DB" ] || update_db

    local found=0

    # Read bad processes from our local database
    while IFS= read -r rat_proc || [ -n "$rat_proc" ]; do
        [ -z "$rat_proc" ] && continue
        if pgrep -fi "$rat_proc" &>/dev/null; then
            echo "🐀 [PROCESS ACTIVE] Found running spy-process: $rat_proc"
            ((found++))
        fi
    done < "$PROCS_DB"

    # Check systemd telemetry
    if systemctl is-active --quiet systemd-journal-upload; then
        echo "⚙️  [SERVICE ACTIVE] Systemd Journal Upload is streaming logs remotely."
        ((found++))
    fi

    # Check hosts file vulnerability
    while IFS= read -r host || [ -n "$host" ]; do
        [ -z "$host" ] && continue
        if ! grep -q "$host" /etc/hosts; then
            echo "🌐 [VULNERABILITY] Telemetry host NOT blocked: $host"
            ((found++))
        fi
    done < "$HOSTS_DB"

    echo "----------------------------------------------------------------"
    echo "📊 System Scan Complete. Found indicators: $found"
}

# --- MODE 2: ISOLATED APP/FOLDER AUDIT ---
scan_app() {
    local target_dir=$1
    if [ -z "$target_dir" ] || [ ! -d "$target_dir" ]; then
        echo "❌ Error: Please specify a valid directory to audit!"
        echo "👉 Example: sudo antiratin scan --app /opt/discord"
        exit 1
    fi

    echo "🕵️‍♂️ [ANTIRATIN] Auditing closed-source directory: $target_dir"
    echo "----------------------------------------------------------------"

    # Шукаємо згадки слів telemetry, analytics, tracker, crashreport всередині бінарників та конфігів програми
    local spy_triggers=$(grep -rIoE "(telemetry|analytics|crashreport|tracker|metrics)" "$target_dir" 2>/dev/null | wc -l)

    if [ "$spy_triggers" -gt 0 ]; then
        echo "⚠️  [WARNING] Found $spy_triggers telemetry/tracking strings inside this app folder!"
        echo "👉 This app is highly likely collecting behavioral analytics."
        echo "💡 Files containing telemetry flags:"
        grep -rloE "(telemetry|analytics|crashreport|tracker|metrics)" "$target_dir" 2>/dev/null | head -n 10
    else
        echo "🛡️  [CLEAN] No obvious telemetry tracking functions spotted inside this folder."
    fi
    echo "----------------------------------------------------------------"
}

# --- FIX PROTOCOL ---
fix_system() {
    echo "🧹 [ANTIRATIN] Running global patch..."
    [ -f "$HOSTS_DB" ] || update_db

    while IFS= read -r host || [ -n "$host" ]; do
        [ -z "$host" ] && continue
        if ! grep -q "$host" /etc/hosts; then
            echo "127.0.0.1 $host" >> /etc/hosts
            echo "🔒 Blocked: $host"
        fi
    done < "$HOSTS_DB"

    echo "✅ Anti-spy wall built successfully!"
}

# Command router
case "$1" in
    update)
        update_db
        ;;
    scan)
        if [ "$2" = "--system" ]; then
            scan_system
        elif [ "$2" = "--app" ]; then
            scan_app "$3"
        else
            show_help
        fi
        ;;
    fix)
        fix_system
        ;;
    help|*)
        show_help
        ;;
esac
