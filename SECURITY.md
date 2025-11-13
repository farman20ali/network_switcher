# Security Policy

## Supported Versions

We release patches for security vulnerabilities. The following versions are currently being supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of Network Switcher seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please do NOT:

- Open a public GitHub issue for security vulnerabilities
- Discuss the vulnerability in public forums, social media, or mailing lists

### Please DO:

1. **Email**: Send details to the repository maintainer (check GitHub profile for contact)
2. **Include**:
   - Type of issue (e.g., privilege escalation, command injection, etc.)
   - Full paths of source file(s) related to the manifestation of the issue
   - The location of the affected source code (tag/branch/commit or direct URL)
   - Any special configuration required to reproduce the issue
   - Step-by-step instructions to reproduce the issue
   - Proof-of-concept or exploit code (if possible)
   - Impact of the issue, including how an attacker might exploit it

### What to expect:

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours
- **Initial Assessment**: We will provide an initial assessment within 5 business days
- **Updates**: We will keep you informed about our progress towards a fix
- **Fix Timeline**: We aim to release security fixes within 30 days of initial report
- **Credit**: We will credit you in the security advisory (unless you prefer to remain anonymous)

## Security Considerations

### NetworkManager Access

Network Switcher requires access to NetworkManager (`nmcli`) commands. This means:

- The application can modify network connections
- It can enable/disable network interfaces
- It requires user-level permissions (not root)

### System Integration

- The application uses systemd user services
- It requires access to the system tray/notification area
- It reads environment variables for display configuration

### Dependencies

We rely on the following dependencies:
- Python 3.6+
- pystray (system tray integration)
- Pillow (image processing)
- NetworkManager (system-level network management)

Please keep these dependencies updated to their latest secure versions.

### Best Practices

For users:
1. Only install from official sources
2. Verify the integrity of downloaded files
3. Keep Python and dependencies updated
4. Review the source code before installation
5. Use the provided installation scripts (they include security checks)

For developers:
1. Follow secure coding practices
2. Validate all user inputs
3. Use subprocess with proper argument handling
4. Avoid shell injection vulnerabilities
5. Handle errors gracefully without exposing sensitive information

## Known Security Limitations

1. **Privilege Level**: The application runs with user privileges and can only modify network connections that the user has permission to modify
2. **Command Execution**: The application executes `nmcli` commands using subprocess
3. **Service Permissions**: When run as a systemd service, it inherits the user's permissions

## Security Updates

Security updates will be:
- Released as patch versions (e.g., 1.0.1)
- Documented in CHANGELOG.md
- Announced in GitHub releases
- Tagged with the `security` label

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Python Security Best Practices](https://python.readthedocs.io/en/stable/library/security_warnings.html)
- [NetworkManager Security](https://networkmanager.dev/)

## Acknowledgments

We would like to thank the security researchers and users who responsibly report vulnerabilities to help keep Network Switcher secure.

---

**Last Updated**: November 12, 2025
