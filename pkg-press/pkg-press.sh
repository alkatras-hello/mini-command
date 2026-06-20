#!/bin/bash

# ==============================================================================
# PACKAGE#PRESS - Smart Compression Tool for Linux (No Password Version)
# Developed by: alkatras-hello
# ==============================================================================

# --- AUTOMATIC DEPENDENCY INSTALLER ---
install_missing_dep() {
    local dep="$1"
    echo "⚠️ Dependency '$dep' is missing."
    read -p "❓ Do you want to install '$dep' automatically? (y/n): " choice

    # Використовуємо case замість [ ], щоб залізобетонно уникнути "too many arguments"
    case "$choice" in
        [yY]|[yY][eE][sS])
            echo "🔄 Detecting package manager..."
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y "$dep"
            elif command -v pacman &> /dev/null; then
                sudo pacman -Sy --noconfirm "$dep"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y "$dep"
            else
                echo "❌ Error: Package manager not found. Install '$dep' manually."
                exit 1
            fi
            ;;
        *)
            echo "❌ Error: Cannot proceed without '$dep'. Exiting."
            exit 1
            ;;
    esac
}

# --- DEPENDENCY CHECKER ---
check_dependencies() {
    if ! command -v tar &> /dev/null; then install_missing_dep "tar"; fi
    if ! command -v xz &> /dev/null; then install_missing_dep "xz"; fi
}

# --- ENGLISH INTERFACE MESSAGES ---
msg_error_exist="❌ Error: File or folder '%s' does not exist!\n"
msg_error_action="❌ Error: Unknown action! Use 'c' to compress or 'x' to extract.\n"
msg_error_type="❌ Error: Unknown mode! Use 'f' for file or 'd' for directory.\n"
msg_usage="🔧 Usage: pkg-press [action] [mode] [target]\n  Actions:\n    c - compress\n    x - extract\n  Modes:\n    f - file\n    d - directory (folder)\n"

# --- COMPRESSION LOGIC ---
compress_target() {
    local mode="$1"
    local source="$2"

    if [ ! -e "$source" ]; then
        printf "$msg_error_exist" "$source"
        exit 1
    fi

    check_dependencies

    if [ "$mode" == "d" ]; then
        local output="${source%/}.tar.xz"
        echo "📦 Compressing DIRECTORY: $source -> $output"
        echo "🗜️ Applying maximum compression (-9)... Please wait..."
        tar -cf - "$source" | xz -9 -c > "$output"
        local final_output="$output"
    elif [ "$mode" == "f" ]; then
        local output="${source}.xz"
        echo "📄 Compressing FILE: $source -> $output"
        echo "🗜️ Processing... Please wait..."
        xz -9k -c "$source" > "$output"
        local final_output="$output"
    else
        printf "$msg_error_type"
        exit 1
    fi

    if [ $? -eq 0 ] && [ -f "$final_output" ]; then
        echo "✅ Done!"

        # Рахуємо точний розмір у байтах АБО кілобайтах
        local orig_size=$(ls -lh "$source" | awk '{print $5}')
        local comp_size=$(ls -lh "$final_output" | awk '{print $5}')

        echo "📉 Original size: $orig_size"
        echo "📉 Compressed size: $comp_size"

        echo "🧹 Removing original: $source"
        rm -rf "$source"
    else
        echo "❌ Compression failed."
    fi
}

# --- EXTRACTION LOGIC ---
extract_target() {
    local mode="$1"
    local archive="$2"

    if [ ! -f "$archive" ]; then
        printf "$msg_error_exist" "$archive"
        exit 1
    fi

    check_dependencies

    echo "🔓 Extracting: $archive"

    if [ "$mode" == "d" ]; then
        case "$archive" in
            *.tar.xz|*.txz)        tar -xf "$archive" ;;
            *.tar.gz|*.tgz)        tar -xzf "$archive" ;;
            *.zip)
                if ! command -v unzip &> /dev/null; then install_missing_dep "unzip"; fi
                unzip "$archive"
                ;;
            *)                     echo "❌ Unknown folder archive format!" ;;
        esac
    elif [ "$mode" == "f" ]; then
        case "$archive" in
            *.xz)                  xz -dk -c "$archive" > "${archive%.xz}" ;;
            *)                     echo "❌ Unknown file compression format!" ;;
        esac
    else
        printf "$msg_error_type"
        exit 1
    fi
if [ $? -eq 0 ]; then
        echo "✅ Successfully extracted!"
        echo "🧹 Removing archive file: $archive"
        rm -f "$archive"
    fi
}

# --- MAIN ENTRY POINT / ARGUMENT CHECK ---
if [ -z "$1" ] [ -z "$2"] [ -z "$3" ]; then
    printf "$msg_usage"
    exit 1
fi

case "$1" in
    c) compress_target "$2" "$3" ;;
    x) extract_target "$2" "$3" ;;
    *) printf "$msg_error_action"; exit 1 ;;
esac
