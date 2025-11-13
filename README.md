# Network Switcher Tray App

A simple, lightweight Linux system tray application to quickly switch between network modes (Wi-Fi, Wired, Both, Hotspot, or disable all) using NetworkManager (`nmcli`).

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.6+-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![Status](https://img.shields.io/badge/status-production--ready-brightgreen.svg)

## 📥 Download

**Latest Release:** [v1.0.0](https://github.com/farman20ali/network_switcher/releases/latest)

```bash
# Download the .deb package
wget https://github.com/farman20ali/network_switcher/releases/download/v1.0.0/network-switcher_1.0.0-1_all.deb

# Install
sudo dpkg -i network-switcher_1.0.0-1_all.deb

# Start the service
systemctl --user daemon-reload && systemctl --user enable --now network-switcher.service
```

See [Installation Guide](#-installation-via-deb-package-ubuntudebian) for detailed instructions.

## ✨ Features
- 🖥️ System tray icon with an intuitive menu for network switching
- 📶 Supports Wi-Fi, Wired, Both, Hotspot, and disabling all connections
- 📊 Shows current connection status in the menu
- 🔄 Automatic connection detection and status updates
- 🛡️ Graceful exit and tray icon removal on Ctrl+C or SIGTERM
- 🎨 Uses Unicode icons for menu items (customizable)
- 🚀 **Automatic dependency installation** - No manual setup needed!
- ⚙️ Runs as a systemd service (optional)
- 📦 **Available as .deb packages** for Debian/Ubuntu
- 🔧 Command-line interface with `--version` and `--debug` options
- 📝 Comprehensive logging to `~/.config/network-switcher/`

## 📋 Requirements

### System Requirements
- **Operating System**: Linux with GUI (X11 or Wayland)
- **Python**: 3.6 or higher
- **NetworkManager**: `nmcli` command-line tool
- **systemd**: For service management (optional)

### Python Dependencies
- `pystray` >= 0.19.4
- `Pillow` >= 9.0.0

**Note:** The installation script automatically installs all missing dependencies!

## � Installation via .deb Package (Ubuntu/Debian)

The easiest way to install on Ubuntu/Debian systems is using the pre-built .deb package:

### Step 1: Install the Package

```bash
sudo dpkg -i network-switcher_1.0.0-1_all.deb
```

### Step 2: Start the Service

You have **three options** after installation:

#### Option 1: Start Immediately ⚡ (Fastest)

```bash
systemctl --user daemon-reload && systemctl --user enable --now network-switcher.service
```

The tray icon appears instantly!

#### Option 2: Auto-Enable on Next Login 🔄 (Easiest - No Commands Needed!)

Just logout and login again (or open a new terminal):

```bash
bash -l
```

The service will **automatically enable and start** on your next login! 

**How it works:** The package installs a one-time setup script that automatically runs when you open a new login shell. It enables the service, starts it, shows a success message, and removes itself. Perfect for users who don't want to run manual commands!

#### Option 3: Start Manually Later 🔧

```bash
systemctl --user start network-switcher.service
```

**That's it!** Choose the option that works best for you.

### Verify Installation

Check if the service is running:
```bash
systemctl --user status network-switcher.service
```

### Uninstalling the .deb Package

```bash
# Stop the service first
systemctl --user stop network-switcher.service
systemctl --user disable network-switcher.service

# Remove the package
sudo apt remove network-switcher
```

### Building Your Own .deb Package

If you want to build the package from source:

```bash
./build-deb.sh
```

This will create `network-switcher_1.0.0-1_all.deb` in the current directory.

## �🚀 Quick Installation

### Automatic Installation (Recommended)

Simply run the installation script:

```bash
./install.sh
```

The script will:
1. ✅ Check for all required system dependencies
2. ✅ Verify Python version compatibility
3. ✅ Install Python packages automatically
4. ✅ Make the script executable
5. ✅ Set up the systemd service
6. ✅ Optionally enable and start the service

**That's it!** The Network Switcher will be installed and ready to use.

### Manual Installation

If the automatic installation script doesn't work or you prefer manual installation, follow these steps:

#### Step 1: Install System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install python3 python3-pip network-manager
```

**Fedora/RHEL:**
```bash
sudo dnf install python3 python3-pip NetworkManager
```

**Arch Linux:**
```bash
sudo pacman -S python python-pip networkmanager
```

#### Step 2: Install Python Dependencies

```bash
pip3 install --user -r requirements.txt
```

Or install manually:
```bash
pip3 install --user pystray Pillow
```

#### Step 3: Make the Script Executable

```bash
chmod +x network_switcher.py
```

#### Step 4: Create Network Icon (Optional)

If you don't have a `network_icon.png` file, generate one:
```bash
python3 create_icon.py
```

Or provide your own 64x64 PNG icon named `network_icon.png`.

## 📖 Usage

### Method 1: Using systemd Service (Recommended)

If you used the installation script and enabled the service, it's already running! 

**Control the service:**

```bash
# Start the service
systemctl --user start network-switcher.service

# Stop the service
systemctl --user stop network-switcher.service

# Check service status
systemctl --user status network-switcher.service

# View logs
journalctl --user -u network-switcher.service -f

# Enable service to start on login
systemctl --user enable network-switcher.service

# Disable service
systemctl --user disable network-switcher.service
```

### Method 2: Running Manually

If you prefer to run the application without the systemd service:

```bash
# Run in foreground
./network_switcher.py

# Run in background
nohup ./network_switcher.py </dev/null >/dev/null 2>&1 &
```

### Method 3: Manual systemd Service Setup

If the installation script didn't set up the service or you want to do it manually:
### Method 3: Manual systemd Service Setup

If the installation script didn't set up the service or you want to do it manually:

1. Create the systemd user service directory:
   ```bash
   mkdir -p ~/.config/systemd/user/
   ```

2. Copy the service file to the systemd directory:
   ```bash
   cp network-switcher.service ~/.config/systemd/user/
   ```

3. **Important:** Edit the service file to use absolute paths:
   ```bash
   nano ~/.config/systemd/user/network-switcher.service
   ```
   
   Replace the `ExecStart` line with the full path to your script:
   ```
   ExecStart=/full/path/to/network_switcher.py
   ```

4. Reload systemd configuration:
   ```bash
   systemctl --user daemon-reload
   ```

5. Enable the service to start on login:
   ```bash
   systemctl --user enable network-switcher.service
   ```

6. Start the service:
   ```bash
   systemctl --user start network-switcher.service
   ```

## 🗑️ Uninstallation

### Automatic Uninstallation (Recommended)

Simply run the uninstallation script:

```bash
./uninstall.sh
```

The script will:
- ✅ Stop and disable the systemd service
- ✅ Remove the service file
- ✅ Optionally remove Python dependencies
- ✅ Keep the application files (so you can reinstall if needed)

### Manual Uninstallation

If you need to uninstall manually:

1. Stop and disable the service:
   ```bash
   systemctl --user stop network-switcher.service
   systemctl --user disable network-switcher.service
   ```

2. Remove the service file:
   ```bash
   rm -f ~/.config/systemd/user/network-switcher.service
   ```

3. Reload systemd:
   ```bash
   systemctl --user daemon-reload
   ```

4. Optionally remove Python dependencies:
   ```bash
   pip3 uninstall pystray Pillow
   ```

5. Remove the application directory:
   ```bash
   rm -rf /path/to/network_switcher
   ```

## 🎛️ Menu Options

The system tray icon provides the following options:

- **📶 Switch to Wi-Fi**: Enables Wi-Fi and disables wired connection
- **🌐 Switch to Wired**: Enables wired connection and disables Wi-Fi
- **🔄 Enable Both Wi-Fi and Wired**: Enables both connections simultaneously
- **📡 Turn On Hotspot**: Enables hotspot mode (requires wired connection)
- **❌ Stop All Connections**: Disables all network connections
- **Quit**: Exits the application

The current connection status is displayed at the top of the menu.

## 🔧 Troubleshooting

### The tray icon doesn't appear

1. **Check if your desktop environment supports system tray icons:**
   - GNOME users may need the [AppIndicator extension](https://extensions.gnome.org/extension/615/appindicator-support/)
   - KDE Plasma, XFCE, and MATE usually support tray icons by default

2. **Check if the service is running:**
   ```bash
   systemctl --user status network-switcher.service
   ```

3. **View logs for errors:**
   ```bash
   journalctl --user -u network-switcher.service -n 50
   ```

4. **Try running manually to see errors:**
   ```bash
   ./network_switcher.py
   ```

### Missing dependencies error

If you see errors about missing dependencies, install them:

```bash
# Install system dependencies
sudo apt-get install python3 python3-pip network-manager  # Ubuntu/Debian
sudo dnf install python3 python3-pip NetworkManager       # Fedora/RHEL
sudo pacman -S python python-pip networkmanager           # Arch Linux

# Install Python dependencies
pip3 install --user pystray Pillow
```

### NetworkManager not found

The application requires NetworkManager and the `nmcli` command. Install it:

```bash
sudo apt-get install network-manager  # Ubuntu/Debian
sudo dnf install NetworkManager       # Fedora/RHEL
sudo pacman -S networkmanager         # Arch Linux
```

Then enable and start NetworkManager:
```bash
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
```

### Permission denied errors

Make sure the script is executable:
```bash
chmod +x network_switcher.py
```

### Hotspot not working

1. Ensure you have a wired connection active
2. Check that your Wi-Fi adapter supports AP mode:
   ```bash
   iw list | grep -A 10 "Supported interface modes"
   ```
3. Verify NetworkManager has a hotspot connection configured

### Icon not found

If you see a "network_icon.png not found" message:

1. Generate a default icon:
   ```bash
   python3 create_icon.py
   ```

2. Or provide your own 64x64 PNG icon named `network_icon.png` in the application directory

## ⚙️ Configuration

### Customizing Connection Names

The script automatically detects your Ethernet and Hotspot connection names. If detection fails or you want to use custom names, edit `network_switcher.py`:

```python
# Near the top of the file
conn_name = "Your-Ethernet-Connection-Name"
hotspot_name = "Your-Hotspot-Name"
```

### Customizing Menu Icons

To change the Unicode icons, edit the `create_menu_items()` function in `network_switcher.py`:

```python
wifi_icon = "📶"     # Change to your preferred icon
wired_icon = "🌐"    # Change to your preferred icon
# ... etc
```

### Changing Log Level

To see more detailed logs, edit the logging configuration in `network_switcher.py`:

```python
logging.basicConfig(level=logging.DEBUG, stream=sys.stdout)
```

## 📁 Project Structure

```
network_switcher/
├── network_switcher.py          # Main application script
├── network-switcher.service     # systemd service file template
├── network_switcher.desktop     # Desktop entry file
├── requirements.txt             # Python dependencies
├── install.sh                   # Installation script
├── uninstall.sh                 # Uninstallation script
├── create_icon.py               # Icon generation script
├── network_icon.png             # Application icon (create or provide)
├── README.md                    # This file
├── LICENSE                      # MIT License
└── .gitignore                   # Git ignore rules
```

## 🤝 Contributing

Contributions are welcome! Here are some ways you can contribute:

- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📖 Improve documentation
- 🔧 Submit pull requests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [pystray](https://github.com/moses-palmer/pystray) for system tray functionality
- Uses [Pillow](https://python-pillow.org/) for image processing
- Relies on [NetworkManager](https://networkmanager.dev/) for network management

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review existing issues on GitHub
3. Create a new issue with:
   - Your Linux distribution and version
   - Python version (`python3 --version`)
   - Error messages or logs
   - Steps to reproduce the issue

---

**Made with ❤️ for the Linux community**

---

**Author:** Your Name Here
