# Contributing to Network Switcher

Thank you for your interest in contributing to Network Switcher! This document provides guidelines and instructions for contributing.

## 🤝 How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:

1. **Clear title**: Describe the bug briefly
2. **Description**: Detailed explanation of the issue
3. **Steps to reproduce**: List the exact steps to reproduce the bug
4. **Expected behavior**: What you expected to happen
5. **Actual behavior**: What actually happened
6. **Environment details**:
   - Linux distribution and version
   - Python version (`python3 --version`)
   - Desktop environment (GNOME, KDE, etc.)
   - NetworkManager version (`nmcli --version`)
7. **Logs**: Include relevant error messages or logs
   ```bash
   journalctl --user -u network-switcher.service -n 50
   ```

### Suggesting Features

Feature suggestions are welcome! Please create an issue with:

1. **Feature description**: What feature would you like to see?
2. **Use case**: Why is this feature needed?
3. **Proposed solution**: How do you think it should work?
4. **Alternatives**: Any alternative solutions you've considered?

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**:
   - Follow the existing code style
   - Add comments for complex logic
   - Update documentation if needed
4. **Test your changes**:
   - Test on your Linux system
   - Ensure all existing functionality still works
   - Test the installation and uninstallation scripts
5. **Commit your changes**:
   ```bash
   git commit -m "Add: brief description of your changes"
   ```
   Use conventional commit messages:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Update:` for updates to existing features
   - `Docs:` for documentation changes
   - `Refactor:` for code refactoring
6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**:
   - Provide a clear description of your changes
   - Reference any related issues
   - Include screenshots if applicable

## 🔧 Development Setup

### Prerequisites

- Linux system with GUI
- Python 3.6 or higher
- NetworkManager
- Git

### Setting Up Development Environment

1. **Clone the repository**:
   ```bash
   git clone https://github.com/farman20ali/network_switcher.git
   cd network_switcher
   ```

2. **Install dependencies**:
   ```bash
   pip3 install --user -r requirements.txt
   ```

3. **Make the script executable**:
   ```bash
   chmod +x network_switcher.py
   ```

4. **Create a test icon** (if needed):
   ```bash
   python3 create_icon.py
   ```

5. **Run the application**:
   ```bash
   ./network_switcher.py
   ```

### Testing

Before submitting a pull request:

1. **Test basic functionality**:
   - Switch between Wi-Fi and Wired
   - Enable both connections
   - Enable hotspot (if supported)
   - Disable all connections
   - Check status display

2. **Test the installation script**:
   ```bash
   ./install.sh
   ```

3. **Test the uninstallation script**:
   ```bash
   ./uninstall.sh
   ```

4. **Check for errors**:
   ```bash
   python3 -m py_compile network_switcher.py
   ```

## 📝 Code Style Guidelines

- **Python Version**: Write code compatible with Python 3.6+
- **Indentation**: Use 4 spaces (no tabs)
- **Line Length**: Keep lines under 100 characters when possible
- **Naming**:
  - Functions: `snake_case`
  - Classes: `PascalCase`
  - Constants: `UPPER_CASE`
- **Comments**: Add comments for complex logic
- **Docstrings**: Use docstrings for functions and classes
- **Error Handling**: Use try-except blocks for external commands
- **Logging**: Use the logging module instead of print statements

### Example Code Style

```python
#!/usr/bin/env python3

import subprocess
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)

def get_connection_status():
    """
    Get the current network connection status.
    
    Returns:
        tuple: (wifi_status, ethernet_status, hotspot_status)
    """
    try:
        # Get WiFi status
        wifi_status = subprocess.check_output(
            ["nmcli", "-t", "-f", "WIFI", "radio"]
        ).decode().strip()
        
        return wifi_status
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to get connection status: {e}")
        return "unknown"
```

## 🐛 Debugging Tips

### Running with Debug Logging

Edit `network_switcher.py` and change:
```python
logging.basicConfig(level=logging.DEBUG, stream=sys.stdout)
```

### Viewing Service Logs

```bash
journalctl --user -u network-switcher.service -f
```

### Testing nmcli Commands

Test NetworkManager commands manually:
```bash
# List connections
nmcli connection show

# Check WiFi status
nmcli radio wifi

# Check device status
nmcli device status
```

## 📋 Areas for Contribution

Here are some areas where contributions would be especially welcome:

### Features
- [ ] Configuration file support
- [ ] GUI settings dialog
- [ ] Notification support for connection changes
- [ ] VPN integration
- [ ] Network connection profiles
- [ ] Keyboard shortcuts
- [ ] Multiple hotspot configurations

### Improvements
- [ ] Better icon detection for different desktop environments
- [ ] Wayland compatibility improvements
- [ ] Error handling improvements
- [ ] Performance optimizations
- [ ] Automated tests

### Documentation
- [ ] Video tutorials
- [ ] More troubleshooting scenarios
- [ ] Distribution-specific guides
- [ ] FAQ section
- [ ] Translations

### Platform Support
- [ ] Snap package
- [ ] Flatpak package
- [ ] AppImage
- [ ] AUR package (Arch Linux)

## 📄 License

By contributing to Network Switcher, you agree that your contributions will be licensed under the MIT License.

## 💬 Questions?

If you have questions about contributing:

1. Check existing issues and discussions
2. Create a new issue with the "question" label
3. Reach out to the maintainers

## 🙏 Thank You!

Thank you for taking the time to contribute to Network Switcher! Every contribution, no matter how small, is valuable and appreciated.
