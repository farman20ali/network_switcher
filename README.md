# Network Switcher Tray App

A simple Linux system tray application to quickly switch between network modes (Wi-Fi, Wired, Both, Hotspot, or disable all) using NetworkManager (`nmcli`).

## Features
- System tray icon with menu for network switching
- Supports Wi-Fi, Wired, Both, Hotspot, and disabling all connections
- Shows current connection status in the menu
- Graceful exit and tray icon removal on Ctrl+C or SIGTERM
- Uses Unicode icons for menu items (can be customized)

## Requirements
- Python 3.6+
- NetworkManager (`nmcli` command-line tool)
- Python packages:
  - pystray
  - pillow

Install dependencies with:
```bash
pip install pystray pillow
```

## Usage
1. Place your network icon as `network_icon.png` in the project directory (64x64 PNG recommended).
2. Make the script executable:
   ```bash
   chmod +x network_switcher.py
   ```
3. Run the app:
   ```bash
   ./network_switcher.py
   ```
   Or run in the background (see `command_file.txt`):
   ```bash
   nohup ./network_switcher.py </dev/null >/dev/null 2>&1 &
   ```

## Menu Options
- 📶 Switch to Wi-Fi
- 🌐 Switch to Wired
- 🔄 Enable Both Wi-Fi and Wired
- 📡 Turn On Hotspot
- ❌ Stop All Connections
- Quit

The current connection status is displayed at the top of the menu.

## Notes
- The script dynamically detects your Ethernet and Hotspot connection names. If your system uses custom names, edit the detection logic as needed.
- Unicode icons may not display on all system trays. You can change them to plain text or small images in the code.
- Logging is set to stdout by default. For persistent logs, edit the logging configuration in the script.

## License
MIT License

---

**Author:** Your Name Here
