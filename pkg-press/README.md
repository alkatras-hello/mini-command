PACKAGE#PRESS - USER MANUAL
​1. WHAT IS PACKAGE#PRESS
​Package#Press is a lightweight and powerful command-line utility for Linux operating systems. It is specifically designed to handle high-ratio file and directory compression using native 'xz' and 'tar' tools. The utility is fully optimized for pure terminal environments (such as TTY virtual consoles) and contains an automatic storage cleanup feature to save disk space.
​2. KEY FEATURES
​High-Efficiency Compression: Utilizes extreme compression levels (-9) based on the LZMA2 algorithm.
​Automated Workspace Cleanup: Safely deletes the source folder or file immediately after a successful compression process. During extraction, it deletes the source archive file as soon as the files are successfully restored.
​Self-Healing Dependencies: Automatically detects if required system binaries like 'tar' or 'xz' are missing and prompts the user for automated installation via apt, pacman, or dnf.
​Clean Environment Operations: Stripped of password or complex encryption subroutines to ensure zero freezing or terminal device errors in TTY configurations.
​3. HOW TO INSTALL THE UTILITY
​To convert the script into a native, global system command that runs from any directory, use the official installation script.
​Step 1: Clean the installer script from potential Windows line ending distortions by running:
sed -i 's/\r$//' install.sh
​Step 2: Execute the installer script with the following command:
bash install.sh
​The installer automatically copies the core utility to the secure system path at /usr/local/bin/pkg-press and assigns full execution privileges.
​4. HOW TO UNINSTALL THE UTILITY
​If you need to wipe the utility and its binaries from your Linux environment, use the dedicated uninstaller script.
​Step 1: Remove potential line ending distortions from the uninstaller script by running:
sed -i 's/\r$//' uninstall.sh
​Step 2: Run the uninstaller script:
bash uninstall.sh
​The uninstaller automatically targets the system paths, removes the global command, and prints a success confirmation message.
​5. COMPLETE USAGE AND EXAMPLES
​Once installed, you no longer need to prefix the script with the bash command. You can directly invoke the global utility using the short name 'pkg-press'.
​COMPRESSION OPERATIONS
​To compress items, use the action flag 'c' followed by the mode flag ('f' for a single file or 'd' for a directory) and specify your target path.
​Example A: Compressing a single text file
pkg-press c f documentation.txt
Result: The tool creates a highly compressed 'documentation.txt.xz' archive and automatically deletes the original 'documentation.txt'.
​Example B: Compressing an entire directory or folder
pkg-press c d source_code
Result: The tool packages the directory into a 'source_code.tar.xz' archive and automatically deletes the original 'source_code' folder.
​EXTRACTION OPERATIONS
​To extract archives back to their original state, use the action flag 'x' followed by the mode flag ('f' for a compressed file or 'd' for a directory archive) and the archive path.
​Example A: Decompressing a single file archive
pkg-press x f documentation.txt.xz
Result: The tool restores the original 'documentation.txt' file and automatically cleans up the 'documentation.txt.xz' archive.
​Example B: Decompressing a folder archive
pkg-press x d source_code.tar.xz
Result: The tool unpacks and restores the original 'source_code' directory structures and automatically cleans up the 'source_code.tar.xz' archive from the system.
