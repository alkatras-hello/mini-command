# mini-command 🛠️

A powerful, growing collection of lightweight, dependency-free, and fast command-line utilities optimized for Linux terminal environments (including pure TTY lines). 

The ultimate goal of this project is to build a comprehensive suite of 30+ essential micro-commands for system administration, automation, networking, and daily console tasks.

Developed by: alkatras-hello

---

## 📥 Global Installation

You can install all available commands at once, or choose to install only the ones you need.

### Option 1: Install Everything (Recommended)
To install the complete suite of tools globally:
`bash
# Clean script from potential line ending issues
sed -i 's/\r$//' install.sh

# Run the master installer
bash install.sh
# 🪓 Uninstallation
​To completely wipe all installed global binaries from your system:
sed -i 's/\r$//' uninstall.sh
bash uninstall.sh

​
