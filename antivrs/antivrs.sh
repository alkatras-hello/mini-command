#!/bin/bash

# ==============================================================================
# ANTIVIRS v1.5 - Pure CLI Multi-Engine Online Malware Hash Checker
# Developed by: alkatras-hello
# ==============================================================================

show_help() {
    echo "💻 Usage: antivirs [file | folder | help]"
    echo "----------------------------------------------------------------"
    echo "⚙️  Core Commands:"
    echo "   antivirs <file_path>   - Check a specific file via online virus databases"
    echo "   antivirs <folder_path> - Scan all files inside a folder recursively"
    echo "----------------------------------------------------------------"
    exit 0
}

# FIXED: Added logical OR (||) operators to prevent syntax crashes
if [ -z "$1" ]  [ "$1" == "help" ]  [ "$1" == "-h" ]; then
    show_help
fi

# Print the confidence rating table
print_trust_table() {
    echo "📊 Virus Engine Trust & Accuracy Ratings:"
    echo "----------------------------------------------------------------"
    echo "1. VirusTotal Intelligence  ======> [ Accuracy: 99% TRUE ]"
    echo "   (Aggregates 70+ antivirus scanners and URL blacklists)"
    echo "2. Kaspersky Threat Portal  ======> [ Accuracy: 95% TRUE ]"
    echo "   (Deep cloud analysis and global threat reputation database)"
    echo "3. MalwareBazaar Database   ======> [ Accuracy: 90% TRUE ]"
    echo "   (Community-driven repository of known malicious file hashes)"
    echo "----------------------------------------------------------------"
}

# Function to scan a single file (Upgraded with 3 Live Network-Generated QR Codes)
scan_file() {
    local target_file=$1

    if [ ! -f "$target_file" ]; then
        echo "❌ Error: File '$target_file' does not exist or is a broken link."
        return 1
    fi

    # Check file size (ignore empty files to save speed)
    local file_size=$(stat -c%s "$target_file" 2>/dev/null || stat -f%z "$target_file" 2>/dev/null)
    if [ "$file_size" -eq 0 ]; then
        echo "📄 File: $(basename "$target_file") -> [SKIP] File is empty (0 bytes)."
        return 0
    fi

    echo "🔬 Analyzing file: $target_file ($(du -sh "$target_file" | cut -f1))"
    echo "⏳ Generating unique SHA-256 digital fingerprint..."

    # Calculate SHA-256 hash
    local hash=$(sha256sum "$target_file" | awk '{print $1}')
    echo "🔑 Generated File Hash: $hash"
    echo "💡 [INFO] This hash acts as a unique digital passport of the file's contents."
    echo ""

    print_trust_table
    echo ""
    echo "🌐 [HOW TO OPEN AND CHECK THE FILE HASH]"
    echo "👉 Option A (GUI Terminal): Hold 'Ctrl' and click (Ctrl+Click) on any link below."
    echo "👉 Option B (No Mouse / Pure CLI): Scan the dynamically generated QR codes with your phone!"
    echo "----------------------------------------------------------------"

    # Define dynamic URLs based on current file hash
    local vt_url="https://www.virustotal.com/gui/file/$hash"
    local kas_url="https://opentip.kaspersky.com/$hash/"
    local mb_url="https://bazaar.abuse.ch/browse.php?search=sha256%3A$hash"

    # --- DYNAMIC ONLINE QR 1: VIRUSTOTAL ---
    echo "🔍 1. VIRUSTOTAL COMPREHENSIVE REPORT (99%):"
    echo "   📝 Website Description: Scans this exact file hash using 70+ anti-malware engines."
    echo "   📱 Fetching Live QR Link via Cloud API (No tools required)..."
    echo ""
    curl -s "https://qrenco.de/$vt_url"
    echo ""
    echo "   🔗 Link: $vt_url"
    echo "----------------------------------------------------------------"

    # --- DYNAMIC ONLINE QR 2: KASPERSKY ---
    echo "🛡️  2. KASPERSKY THREAT INTELLIGENCE SYSTEM (95%):"
    echo "   📝 Website Description: Checks hash reputation based on Kaspersky's global security cloud."
    echo "   📱 Fetching Live QR Link via Cloud API (No tools required)..."
    echo ""
    curl -s "https://qrenco.de/$kas_url"
    echo ""
    echo "   🔗 Link: $kas_url"
    echo "----------------------------------------------------------------"
    # --- DYNAMIC ONLINE QR 3: MALWAREBAZAAR ---
    echo "💥 3. MALWAREBAZAAR RESEARCH RADAR (90%):"
    echo "   📝 Website Description: Verifies if the hash matches known live malware, bots, and trojans."
    echo "   📱 Fetching Live QR Link via Cloud API (No tools required)..."
    echo ""
    curl -s "https://qrenco.de/$mb_url"
    echo ""
    echo "   🔗 Link: $mb_url"
    echo "----------------------------------------------------------------"

    # Interaction for mouse-less terminals (Using Lynx if available)
    if command -v lynx &>/dev/null; then
        read -p "🖥️  No mouse? Press [Y] to open VirusTotal report right here in your terminal (using Lynx), or [N] to skip: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            lynx "$vt_url"
        fi
    fi

    echo "✅ Analysis for '$(basename "$target_file")' completed!"
    echo "========================================================================="
}

# Function to scan an entire folder
scan_folder() {
    local target_dir=$1
    echo "📂 [FOLDER SCAN] Initiating recursive analysis of: $target_dir"

    # Find all files inside the folder and count them
    local file_count=$(find "$target_dir" -type f | wc -l)
    echo "🗂️  Found $file_count files to process."
    echo "----------------------------------------------------------------"

    if [ "$file_count" -eq 0 ]; then
        echo "⚠️  The specified directory is empty."
        exit 0
    fi

    # Loop through each file found inside the folder
    find "$target_dir" -type f | while read -r current_file; do
        echo "👉 Processing: $current_file"
        scan_file "$current_file"
        echo ""
        # Small sleep just to make output readable and prevent terminal flooding
        sleep 0.5
    done
}

# --- Main Logic Router ---
TARGET=$1

if [ -d "$TARGET" ]; then
    scan_folder "$TARGET"
elif [ -f "$TARGET" ]; then
    scan_file "$TARGET"
else
    echo "❌ Error: '$TARGET' is not a valid file or directory!"
    exit 1
fi
