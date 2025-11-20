#!/usr/bin/env python3

"""
Network Switcher - Quick network mode switcher for Linux
A lightweight system tray application for managing network connections.
"""

__version__ = "1.0.0"
__author__ = "Network Switcher Contributors"
__license__ = "MIT"

import subprocess
from pystray import MenuItem as item
import pystray
from PIL import Image
import os
import logging
import sys
import argparse
import signal
import time

# Configure logging with file output
LOG_DIR = os.path.expanduser("~/.config/network-switcher")
LOG_FILE = os.path.join(LOG_DIR, "network-switcher.log")

# Create log directory if it doesn't exist
os.makedirs(LOG_DIR, exist_ok=True)

# Setup logging to both file and stdout
logging.basicConfig(
    level=logging.DEBUG,  # Changed to DEBUG to see detailed logs
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)

# Parse command-line arguments
def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description='Network Switcher - Quick network mode switcher for Linux',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s              Start the application
  %(prog)s --debug      Start with debug logging
  %(prog)s --version    Show version information
        '''
    )
    parser.add_argument(
        '--version',
        action='version',
        version=f'%(prog)s {__version__}'
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug logging'
    )
    parser.add_argument(
        '--no-service',
        action='store_true',
        help='Run in foreground (do not daemonize)'
    )
    return parser.parse_args()

# Parse arguments early
args = parse_arguments()

# Set debug logging if requested
if args.debug:
    logging.getLogger().setLevel(logging.DEBUG)
    logging.debug("Debug logging enabled")

logging.info(f"Network Switcher v{__version__} starting...")
logging.info(f"Log file: {LOG_FILE}")

# Function to find the Ethernet connection name dynamically
def get_ethernet_connection_name(default="connection-lan"):
    try:
        output = subprocess.check_output(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]).decode().strip()
        for line in output.splitlines():
            name, type_ = line.split(":")
            if type_ == "802-3-ethernet":
                return name
    except subprocess.CalledProcessError as e:
        logging.error(f"Error retrieving Ethernet connection name: {e}")
    return default

# Function to find the Hotspot connection name
def get_hotspot_connection_name(default="Hotspot"):
    try:
        output = subprocess.check_output(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]).decode().strip()
        for line in output.splitlines():
            name, type_ = line.split(":")
            if type_ == "802-11-wireless" and "hotspot" in name.lower():
                return name
    except subprocess.CalledProcessError as e:
        logging.error(f"Error retrieving Hotspot connection name: {e}")
    return default

# Define the Ethernet and Hotspot connection names
conn_name = get_ethernet_connection_name()
hotspot_name = get_hotspot_connection_name()

# Helper function to validate and enable the wired connection
def validate_and_enable_wired_connection():
    try:
        wired_status = subprocess.check_output(["nmcli", "-t", "-f", "DEVICE,STATE", "device", "status"]).decode().strip()
        wired_connected = any(line for line in wired_status.splitlines() if conn_name in line and "connected" in line)

        if not wired_connected:
            logging.info("Wired connection not active. Attempting to enable...")
            subprocess.run(["nmcli", "c", "up", conn_name], check=True)
            return True
        return True  # Wired connection is already active
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to enable wired connection: {e}")
        return False

# Function to disable all network connections
def disable_all_connections():
    try:
        logging.info("Disabling all network connections...")
        subprocess.run(["nmcli", "r", "wifi", "off"], check=True)
        subprocess.run(["nmcli", "c", "down", conn_name], check=True)
        logging.info("All network connections disabled.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to disable all network connections: {e}")

# Function to open network settings
def open_network_settings():
    """Open the system's network settings panel"""
    try:
        # Try different desktop environments' network settings applications
        settings_apps = [
            # GNOME (Ubuntu, Fedora, etc.)
            ["gnome-control-center", "wifi"],
            # Alternative GNOME command
            ["gnome-control-center", "network"],
            # KDE Plasma
            ["kcmshell5", "kcm_networkmanagement"],
            # NetworkManager connection editor (works on most DEs)
            ["nm-connection-editor"],
            # XFCE
            ["xfce4-settings-manager", "--socket-id=network"],
            # Fallback: try to open generic settings
            ["gnome-control-center"],
            ["systemsettings5"],
        ]
        
        for cmd in settings_apps:
            try:
                # Use Popen with stderr suppression to avoid error messages
                subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                logging.info(f"Opened network settings using: {' '.join(cmd)}")
                return
            except FileNotFoundError:
                continue
            except Exception as e:
                logging.debug(f"Failed to open settings with {cmd}: {e}")
                continue
        
        # If all else fails, log an error
        logging.error("Could not find a suitable network settings application")
        
    except Exception as e:
        logging.error(f"Failed to open network settings: {e}")

# Function to disable the hotspot
def disable_hotspot():
    try:
        active_connections = subprocess.check_output(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]).decode().strip()
        if any(hotspot_name in line for line in active_connections.splitlines()):
            subprocess.run(["nmcli", "con", "down", hotspot_name], check=True)
            logging.info("Hotspot disabled successfully.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to disable hotspot: {e}")

# Function to enable the hotspot
def enable_hotspot():
    try:
        if not validate_and_enable_wired_connection():
            logging.error("Cannot enable hotspot without a wired connection.")
            return

        subprocess.run(["nmcli", "r", "wifi", "on"], check=True)
        subprocess.run(["nmcli", "con", "up", hotspot_name], check=True)
        logging.info("Hotspot enabled successfully.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to enable hotspot: {e}")

# Define the command to switch to Wi-Fi
def switch_to_wifi(icon, item):
    try:
        disable_hotspot()
        subprocess.run(["nmcli", "r", "wifi", "on"], check=True)
        subprocess.run(["nmcli", "c", "down", conn_name], check=True)
        time.sleep(2)  # Wait for WiFi to connect
        update_menu(icon)
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to switch to Wi-Fi: {e}")

# Define the command to switch to a wired connection
def switch_to_wired(icon, item):
    try:
        disable_hotspot()
        subprocess.run(["nmcli", "c", "up", conn_name], check=True)
        subprocess.run(["nmcli", "r", "wifi", "off"], check=True)
        time.sleep(1)  # Wait for connection to establish
        update_menu(icon)
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to switch to wired connection: {e}")

# Define the command to enable both Wi-Fi and wired connection
def switch_to_both(icon, item):
    try:
        disable_hotspot()
        subprocess.run(["nmcli", "r", "wifi", "on"], check=True)
        subprocess.run(["nmcli", "c", "up", conn_name], check=True)
        time.sleep(2)  # Wait for both connections to establish
        update_menu(icon)
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to enable both Wi-Fi and wired connection: {e}")

# Define the command to enable the hotspot
def switch_to_hotspot(icon, item):
    try:
        enable_hotspot()
        update_menu(icon)
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to enable hotspot: {e}")

# Define the command to disable all network connections
def stop_all_connections(icon, item):
    try:
        disable_all_connections()
        update_menu(icon)
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to disable all connections: {e}")

# Get the current connection status
def get_connection_status():
    # Check if Wi-Fi radio is enabled
    try:
        wifi_status = subprocess.check_output(["nmcli", "-t", "-f", "WIFI", "radio"]).decode().strip()
    except subprocess.CalledProcessError:
        wifi_status = "unknown"
    
    # Get the current Wi-Fi SSID (network name) and check if actually connected
    wifi_ssid = None
    wifi_connected = False
    try:
        # Get active Wi-Fi connection name
        active_wifi = subprocess.check_output(
            ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        ).decode().strip()
        
        for line in active_wifi.splitlines():
            parts = line.split(':')
            if len(parts) >= 3 and '802-11-wireless' in parts[1]:
                wifi_ssid = parts[0]
                wifi_connected = True
                logging.debug(f"WiFi detected: {wifi_ssid}")
                break
    except subprocess.CalledProcessError:
        wifi_ssid = None
        wifi_connected = False

    # Check if ethernet connection is active
    ethernet_status = "disconnected"
    try:
        active_connections = subprocess.check_output(
            ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        ).decode().strip()
        
        for line in active_connections.splitlines():
            parts = line.split(':')
            if len(parts) >= 2 and '802-3-ethernet' in parts[1]:
                ethernet_status = "connected"
                logging.debug(f"Ethernet detected: {parts[0]}")
                break
    except subprocess.CalledProcessError:
        ethernet_status = "unknown"

    try:
        hotspot_status = subprocess.check_output(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]).decode().strip()
        hotspot_status = [line for line in hotspot_status.splitlines() if hotspot_name in line]
        hotspot_status = "active" if hotspot_status else "inactive"
    except subprocess.CalledProcessError:
        hotspot_status = "unknown"

    logging.debug(f"Status: wifi_connected={wifi_connected}, ethernet={ethernet_status}, hotspot={hotspot_status}, ssid={wifi_ssid}")
    return wifi_status, wifi_connected, ethernet_status, hotspot_status, wifi_ssid

# Helper function to create the menu items
def create_menu_items(icon):
    # Unicode icons are used for menu labels. If you see display issues, use plain text or small images instead.
    wifi_icon = "📶"  # Unicode character for Wi-Fi icon
    wired_icon = "🌐"  # Unicode character for wired connection icon
    both_icon = "🔄"   # Unicode character for both connections icon
    hotspot_icon = "📡"  # Unicode character for hotspot icon
    stop_icon = "❌"  # Unicode character for stop icon
    settings_icon = "⚙️"  # Unicode character for settings icon

    wifi_status, wifi_connected, ethernet_status, hotspot_status, wifi_ssid = get_connection_status()

    menu_items = [
        item(f"{wifi_icon} Switch to Wi-Fi", switch_to_wifi),
        item(f"{wired_icon} Switch to Wired", switch_to_wired),
        item(f"{both_icon} Enable Both Wi-Fi and Wired", switch_to_both),
        item(f"{hotspot_icon} Turn On Hotspot", switch_to_hotspot),
        item(f"{stop_icon} Stop All Connections", stop_all_connections),
        pystray.Menu.SEPARATOR,
        item(f"{settings_icon} Wi-Fi Settings", lambda: open_network_settings()),
        pystray.Menu.SEPARATOR,
        item("Quit", lambda icon, item: icon.stop())
    ]

    # Add a label indicating the current connection status with Wi-Fi SSID
    # Check if both WiFi and Wired are connected
    if wifi_connected and ethernet_status == "connected" and hotspot_status == "inactive":
        if wifi_ssid:
            menu_items.insert(0, item(f"{both_icon} Current Connection: Both Wi-Fi and Wired\n{wifi_icon} Network: {wifi_ssid}", lambda: None, enabled=False))
        else:
            menu_items.insert(0, item(f"{both_icon} Current Connection: Both Wi-Fi and Wired", lambda: None, enabled=False))
    # Check if only WiFi is connected
    elif wifi_connected and hotspot_status == "inactive":
        if wifi_ssid:
            menu_items.insert(0, item(f"{wifi_icon} Current Connection: Wi-Fi\n{wifi_icon} Network: {wifi_ssid}", lambda: None, enabled=False))
        else:
            menu_items.insert(0, item(f"{wifi_icon} Current Connection: Wi-Fi", lambda: None, enabled=False))
    # Check if only Wired is connected
    elif ethernet_status == "connected" and hotspot_status == "inactive":
        menu_items.insert(0, item(f"{wired_icon} Current Connection: Wired", lambda: None, enabled=False))
    # Check if Hotspot is active
    elif hotspot_status == "active":
        menu_items.insert(0, item(f"{hotspot_icon} Current Connection: Hotspot", lambda: None, enabled=False))
    # No connection
    else:
        menu_items.insert(0, item("Current Connection: Not Connected", lambda: None, enabled=False))

    return pystray.Menu(*menu_items)

# Update the menu with the current status
def update_menu(icon):
    try:
        logging.info("Updating menu...")
        icon.menu = create_menu_items(icon)
        # Force update on pystray - different methods for different backends
        if hasattr(icon, 'update_menu'):
            icon.update_menu()
            logging.info("Menu updated via update_menu()")
        else:
            # For AppIndicator backend, recreating menu is enough
            logging.info("Menu recreated (update_menu not available)")
    except Exception as e:
        logging.error(f"Error updating menu: {e}")


# Create the system tray icon and menu
def create_menu():
    # Try multiple paths for icon (system and local installations)
    icon_locations = [
        "/usr/share/pixmaps/network-switcher.png",  # Debian package install
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "network_icon.png"),  # Local
        os.path.join(os.getenv('SNAP', ''), 'bin', 'network_icon.png'),  # Snap
        "/snap/network-switcher/current/bin/network_icon.png",  # Snap absolute
        os.path.expanduser("~/.local/share/network-switcher/network_icon.png"),  # User install
    ]
    
    image_path = None
    for path in icon_locations:
        if path and os.path.isfile(path):
            image_path = path
            logging.debug(f"Found icon at: {image_path}")
            break
    
    if image_path:
        image = Image.open(image_path)
    else:
        logging.warning("Image file not found in any location. Using a default icon.")
        logging.debug(f"Searched paths: {icon_locations}")
        image = Image.new("RGB", (64, 64), "blue")

    icon = pystray.Icon("network_switcher", image, "Network Switcher", create_menu_items(None))

    # Handle signals for graceful exit (removes tray icon on Ctrl+C or SIGTERM)
    def signal_handler(sig, frame):
        logging.info("Exiting and removing tray icon...")
        icon.stop()
        sys.exit(0)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    icon.run()

if __name__ == "__main__":
    create_menu()