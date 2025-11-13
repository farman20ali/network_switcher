---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## 🐛 Bug Description
A clear and concise description of what the bug is.

## 📋 Steps to Reproduce
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## ✅ Expected Behavior
A clear and concise description of what you expected to happen.

## ❌ Actual Behavior
A clear and concise description of what actually happened.

## 🖼️ Screenshots
If applicable, add screenshots to help explain your problem.

## 💻 Environment
Please complete the following information:

- **OS/Distribution**: [e.g., Ubuntu 22.04, Fedora 38, Arch Linux]
- **Desktop Environment**: [e.g., GNOME 42, KDE Plasma 5.27, XFCE 4.18]
- **Python Version**: [output of `python3 --version`]
- **NetworkManager Version**: [output of `nmcli --version`]
- **Installation Method**: [automatic script / manual / other]

## 📝 Logs
Please include relevant logs:

```bash
# Service logs
journalctl --user -u network-switcher.service -n 50

# Or manual run output
./network_switcher.py
```

Paste logs here:
```
[paste logs here]
```

## 🔍 Additional Context
Add any other context about the problem here.

## ✔️ Checklist
- [ ] I have checked the [Troubleshooting](https://github.com/farman20ali/network_switcher#-troubleshooting) section
- [ ] I have run `./check_dependencies.sh` and all dependencies are installed
- [ ] I have searched for similar issues
- [ ] I have included all relevant information above
