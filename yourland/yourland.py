#!/usr/bin/env python3
import curses
import curses.textpad
import os
import time

# ==============================================================================
# YOURLAND v0.7 - Persistent Config Desktop with Global System Menu
# Developed by: alkatras-hello
# ==============================================================================

CONFIG_FILE = "yourland_config.txt"

def load_config():
    """ Load user settings or set defaults """
    config = {"width": 90, "height": 22, "apps": []}
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                lines = f.readlines()
                for line in lines:
                    line = line.strip()
                    if line.startswith("GRID:"):
                        parts = line.split(":")[1].split("x")
                        config["width"] = int(parts[0])
                        config["height"] = int(parts[1])
                    elif line.startswith("APP:"):
                        parts = line.split(":")[1].split("|")
                        config["apps"].append({
                            "name": parts[0], "cmd": parts[1], "key": parts[2],
                            "x": int(parts[3]), "y": int(parts[4])
                        })
        except:
            pass
    return config

def save_config(width, height, apps):
    """ Save everything to txt file so YourLand remembers it next time """
    try:
        with open(CONFIG_FILE, "w") as f:
            f.write(f"GRID:{width}x{height}\n")
            for app in apps:
                f.write(f"APP:{app['name']}|{app['cmd']}|{app['key']}|{app['x']}|{app['y']}\n")
    except:
        pass

def read_stat(filename, default="N/A"):
    path = f"/tmp/yourland/{filename}"
    if os.path.exists(path):
        try:
            with open(path, "r") as f:
                return f.read().strip()
        except:
            return default
    return default

def get_input(stdscr, prompt, y, x):
    curses.curs_set(1)
    stdscr.addstr(y, x, prompt, curses.color_pair(3) | curses.A_BOLD)
    stdscr.refresh()
    stdscr.nodelay(False)
    curses.echo()
    input_bytes = stdscr.getstr(y, x + len(prompt), 30)
    result = input_bytes.decode('utf-8').strip()
    curses.noecho()
    stdscr.nodelay(True)
    curses.curs_set(0)
    return result

def draw_desktop(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)
    stdscr.keypad(True)

    curses.start_color()
    curses.init_pair(1, curses.COLOR_CYAN, curses.COLOR_BLACK)   # Status Bar
    curses.init_pair(2, curses.COLOR_GREEN, curses.COLOR_BLACK)  # Apps / Success
    curses.init_pair(3, curses.COLOR_YELLOW, curses.COLOR_BLACK) # Menu / Settings
    curses.init_pair(4, curses.COLOR_BLUE, curses.COLOR_BLACK)   # Main Desktop Border
    curses.init_pair(5, curses.COLOR_RED, curses.COLOR_BLACK)    # Mouse & Alerts

    # Load persistent settings
    config = load_config()
    custom_width = config["width"]
    custom_height = config["height"]
    custom_apps = config["apps"]

    mouse_y, mouse_x = 8, 15
    icon_size = 2
    settings_y, settings_x = 5, 4

    while True:
        ch = stdscr.getch()

        if ch == ord('q'):
            break

        # Win-Menu triggering mechanism (Maps to 'w' key or KEY_HOME as Win key fallback)
        elif ch == ord('w') or ch == curses.KEY_HOME:
            stdscr.clear()
            h, w = stdscr.getmaxyx()
            curses.textpad.rectangle(stdscr, h//4, w//4, h//4 + 11, w//4 + 45)
            stdscr.attron(curses.color_pair(3))
            stdscr.addstr(h//4 + 1, w//4 + 2, "=== YOURLAND SYSTEM MENU ===")
            stdscr.attroff(curses.color_pair(3))

            stdscr.addstr(h//4 + 3, w//4 + 2, "1: Search App Alphabetically")
            stdscr.addstr(h//4 + 5, w//4 + 2, "s: Shutdown  | r: Reboot")
            stdscr.addstr(h//4 + 6, w//4 + 2, "z: Sleep     | h: Hyper-Sleep (Hibernate)")
            stdscr.addstr(h//4 + 8, w//4 + 2, "Press any other key to close menu...")

            stdscr.refresh()
            stdscr.nodelay(False)
            menu_ch = stdscr.getch()
            stdscr.nodelay(True)

            if menu_ch == ord('1'):
                stdscr.clear()
                search = get_input(stdscr, "Search app by letter: ", h//2, w//4).lower()
                if search:
                    # Filter current active workspace launchers
                    found = [a for a in custom_apps if a["name"].lower().startswith(search)]
                    stdscr.clear()
                    stdscr.addstr(h//2 - 2, w//4, f"--- Results for '{search}' ---", curses.color_pair(2))
                    for idx, app in enumerate(found):
                        stdscr.addstr(h//2 + idx, w//4, f"↳ {app['name']} [Hotkey: {app['key']}]")
                    stdscr.addstr(h//2 + len(found) + 1, w//4, "Press any key to return...")
                    stdscr.refresh()
                    stdscr.nodelay(False)
                    stdscr.getch()
                    stdscr.nodelay(True)

            # Absolute Hardware Power Management Layer
            elif menu_ch == ord('s'): # Shutdown
                os.system("poweroff")
            elif menu_ch == ord('r'): # Reboot
                os.system("reboot")
            elif menu_ch == ord('z'): # Sleep / Suspend to RAM
                os.system("systemctl suspend")
            elif menu_ch == ord('h'): # Hyper-Sleep / Hibernate to Disk
                os.system("systemctl hibernate")

        # Basic mouse physics limits
        elif ch == curses.KEY_UP and mouse_y > 4: mouse_y -= 1
        elif ch == curses.KEY_DOWN and mouse_y < custom_height + 1: mouse_y += 1
        elif ch == curses.KEY_LEFT and mouse_x > 1: mouse_x -= 1
        elif ch == curses.KEY_RIGHT and mouse_x < custom_width - 2: mouse_x += 1

        # Check standard user hotkeys
        if ch != -1 and ch != 10:
            for app in custom_apps:
                if ch == ord(app["key"]):
                    os.system(f"{app['cmd']} &")

        # Mouse press interactions
        if ch == 10 or ch == curses.KEY_ENTER:
            if settings_y <= mouse_y <= settings_y + 1 and settings_x <= mouse_x <= settings_x + (icon_size * 2):
                stdscr.clear()
                h, w = stdscr.getmaxyx()

                stdscr.addstr(h//2 - 4, w//4, "=== CONFIGURATION PANEL ===", curses.color_pair(3))
                opt = get_input(stdscr, "1: New Launcher | 2: Resize Desktop Grid -> ", h//2 - 2, w//4)

                if opt == "1":
                    name = get_input(stdscr, "Enter App Name: ", h//2, w//4)
                    cmd = get_input(stdscr, "Enter Bash Command: ", h//2 + 1, w//4)
                    key = get_input(stdscr, "Assign Custom Hotkey: ", h//2 + 2, w//4)

                    if name and cmd and key:
                        slot = len(custom_apps) + 1
                        icon_x = 4 + (slot * 16)
                        if icon_x + 10 < custom_width:
                            custom_apps.append({
                                "name": name, "cmd": cmd, "key": key[0],
                                "x": icon_x, "y": 5
                            })
                            save_config(custom_width, custom_height, custom_apps)

                elif opt == "2":
                    new_w = get_input(stdscr, f"Set Width (Current {custom_width}): ", h//2, w//4)
                    new_h = get_input(stdscr, f"Set Height (Current {custom_height}): ", h//2 + 1, w//4)
                    if new_w.isdigit() and int(new_w) > 40: custom_width = int(new_w)
                    if new_h.isdigit() and int(new_h) > 10: custom_height = int(new_h)
                    save_config(custom_width, custom_height, custom_apps)

            for app in custom_apps:
                if app["y"] <= mouse_y <= app["y"] + 1 and app["x"] <= mouse_x <= app["x"] + (icon_size * 2):
                    os.system(f"{app['cmd']} &")

        stdscr.clear()
        real_h, real_w = stdscr.getmaxyx()
        render_w = min(custom_width, real_w - 2)
        render_h = min(custom_height, real_h - 2)

        cpu = read_stat("cpu")
        ram = read_stat("ram")
        current_time = read_stat("time")

        # ==============================================================================
        # 1. TOP STATUS BAR
        # ==============================================================================
        stdscr.attron(curses.color_pair(1))
        curses.textpad.rectangle(stdscr, 0, 0, 2, render_w)
        stdscr.addstr(1, 2, f"💻 YOURLAND OS v0.7 | GRID: {render_w}x{render_h}")
        stats = f"| CPU: {cpu} | RAM: {ram} | TIME: {current_time} "
        if len(stats) < render_w - 40:
            stdscr.addstr(1, render_w - len(stats) - 1, stats)
        stdscr.attroff(curses.color_pair(1))

        # ==============================================================================
        # 2. MAIN SPACE
        # ==============================================================================
        stdscr.attron(curses.color_pair(4))
        curses.textpad.rectangle(stdscr, 3, 0, render_h + 1, render_w)
        stdscr.attroff(curses.color_pair(4))

        # Settings
        stdscr.attron(curses.color_pair(3))
        stdscr.addstr(settings_y, settings_x, "██" * icon_size)
        stdscr.addstr(settings_y + 1, settings_x, "Settings")
        stdscr.attroff(curses.color_pair(3))

        # Dynamic Launchers
        stdscr.attron(curses.color_pair(2))
        for app in custom_apps:
            if app["x"] + (icon_size * 2) < render_w - 1:
                stdscr.addstr(app["y"], app["x"], "██" * icon_size)
                stdscr.addstr(app["y"] + 1, app["x"], f"{app['name']} [{app['key']}]")
        stdscr.attroff(curses.color_pair(2))

        stdscr.addstr(render_h, 2, f"🖱️ X:{mouse_x} Y:{mouse_y} | Press [w] for System Win-Menu | [q] to exit.")

        # Render Cursor
        stdscr.attron(curses.color_pair(5) | curses.A_BOLD)
        stdscr.addch(mouse_y, mouse_x, 'X')
        stdscr.attroff(curses.color_pair(5) | curses.A_BOLD)

        stdscr.refresh()
        time.sleep(0.04)

if __name__ == "__main__":
    try:
        curses.wrapper(draw_desktop)
    except KeyboardInterrupt:
        print("\n🛡️ YourLand pipeline safely terminated.")
