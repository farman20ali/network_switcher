#!/usr/bin/env python3

import subprocess
from pystray import MenuItem as item
import pystray
from PIL import Image
import os
import logging
import sys

# Configure logging
logging.basicConfig(level=logging.INFO, stream=sys.stdout)

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
        update_menu(icon)
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to switch to Wi-Fi: {e}")

# Define the command to switch to a wired connection
def switch_to_wired(icon, item):
    try:
        disable_hotspot()
        subprocess.run(["nmcli", "c", "up", conn_name], check=True)
        subprocess.run(["nmcli", "r", "wifi", "off"], check=True)
        update_menu(icon)
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to switch to wired connection: {e}")

# Define the command to enable both Wi-Fi and wired connection
def switch_to_both(icon, item):
    try:
        disable_hotspot()
        subprocess.run(["nmcli", "r", "wifi", "on"], check=True)
        subprocess.run(["nmcli", "c", "up", conn_name], check=True)
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
    try:
        wifi_status = subprocess.check_output(["nmcli", "-t", "-f", "WIFI", "radio"]).decode().strip()
    except subprocess.CalledProcessError:
        wifi_status = "unknown"

    try:
        ethernet_status = subprocess.check_output(["nmcli", "-t", "-f", "DEVICE,STATE", "device", "status"]).decode().strip()
        ethernet_status = [line for line in ethernet_status.splitlines() if conn_name in line and 'connected' in line]
        ethernet_status = "connected" if ethernet_status else "disconnected"
    except subprocess.CalledProcessError:
        ethernet_status = "unknown"

    try:
        hotspot_status = subprocess.check_output(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]).decode().strip()
        hotspot_status = [line for line in hotspot_status.splitlines() if hotspot_name in line]
        hotspot_status = "active" if hotspot_status else "inactive"
    except subprocess.CalledProcessError:
        hotspot_status = "unknown"

    return wifi_status, ethernet_status, hotspot_status

# Helper function to create the menu items
def create_menu_items(icon):
    # Unicode icons are used for menu labels. If you see display issues, use plain text or small images instead.
    wifi_icon = "📶"  # Unicode character for Wi-Fi icon
    wired_icon = "🌐"  # Unicode character for wired connection icon
    both_icon = "🔄"   # Unicode character for both connections icon
    hotspot_icon = "📡"  # Unicode character for hotspot icon
    stop_icon = "❌"  # Unicode character for stop icon

    wifi_status, ethernet_status, hotspot_status = get_connection_status()

    menu_items = [
        item(f"{wifi_icon} Switch to Wi-Fi", switch_to_wifi),
        item(f"{wired_icon} Switch to Wired", switch_to_wired),
        item(f"{both_icon} Enable Both Wi-Fi and Wired", switch_to_both),
        item(f"{hotspot_icon} Turn On Hotspot", switch_to_hotspot),
        item(f"{stop_icon} Stop All Connections", stop_all_connections),
        item("Quit", lambda icon, item: icon.stop())
    ]

    # Add a label indicating the current connection status
    if "enabled" in wifi_status and ethernet_status == "connected" and hotspot_status == "inactive":
        menu_items.insert(0, item(f"{both_icon} Current Connection: Both Wi-Fi and Wired", lambda: None, enabled=False))
    elif "enabled" in wifi_status and hotspot_status == "inactive":
        menu_items.insert(0, item(f"{wifi_icon} Current Connection: Wi-Fi", lambda: None, enabled=False))
    elif ethernet_status == "connected" and hotspot_status == "inactive":
        menu_items.insert(0, item(f"{wired_icon} Current Connection: Wired", lambda: None, enabled=False))
    elif hotspot_status == "active":
        menu_items.insert(0, item(f"{hotspot_icon} Current Connection: Hotspot", lambda: None, enabled=False))
    else:
        menu_items.insert(0, item("Current Connection: Not Connected", lambda: None, enabled=False))

    return pystray.Menu(*menu_items)

# Update the menu with the current status
def update_menu(icon):
    icon.menu = create_menu_items(icon)
    # Not all pystray backends support update_menu; handle gracefully
    if hasattr(icon, 'update_menu'):
        try:
            icon.update_menu()
        except Exception as e:
            logging.warning(f"update_menu() not supported: {e}")


# Create the system tray icon and menu
def create_menu():
    image_path = "network_icon.png"
    if os.path.isfile(image_path):
        image = Image.open(image_path)
    else:
        logging.error(f"Image file {image_path} not found. Using a default icon.")
        image = Image.new("RGB", (64, 64), "blue")

    icon = pystray.Icon("network_switcher", image, "Network Switcher", create_menu_items(None))

    # Handle signals for graceful exit (removes tray icon on Ctrl+C or SIGTERM)
    import signal
    def signal_handler(sig, frame):
        logging.info("Exiting and removing tray icon...")
        icon.stop()
        sys.exit(0)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    icon.run()

if __name__ == "__main__":
    create_menu()