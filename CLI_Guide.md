# sysproxy CLI Guide

`sysproxy` is a command-line tool provided by SystemProxyKit for managing macOS system proxy settings.

## Installation and Usage

### Development Environment
```bash
cd /path/to/SystemProxyKit
swift run sysproxy [command]
```

### Build and Install
```bash
swift build -c release
sudo cp .build/release/sysproxy /usr/local/bin/
sysproxy [command]
```

---

## Command Overview

| Command | Description | Requires Root |
|---------|-------------|:-------------:|
| `list` | List all network services | ❌ |
| `get` | Get proxy configuration | ❌ |
| `set` | Set proxy configuration | ✅ |
| `disable` | Disable proxies | ✅ |

---

## list - List Network Services

List all available network services on the system.

```bash
sysproxy list [OPTIONS]
```

### Options

| Option | Description |
|--------|-------------|
| `-e, --enabled-only` | Show only enabled services |
| `-v, --verbose` | Show detailed information |

### Examples

```bash
# List all services
sysproxy list

# List only enabled services
sysproxy list --enabled-only

# Show detailed information
sysproxy list --verbose
```

### Output Example

```
Available Network Services:
  ✓ Wi-Fi
  ✓ Ethernet
  ✗ VPN (Disabled)

Total: 3 service(s)
```

---

## get - Get Proxy Configuration

Get current proxy configuration for a specified network interface.

```bash
sysproxy get <INTERFACE> [OPTIONS]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `<INTERFACE>` | Network interface name, e.g., `Wi-Fi`, `Ethernet` |

### Options

| Option | Description |
|--------|-------------|
| `-j, --json` | Output in JSON format |

### Examples

```bash
# Get Wi-Fi proxy configuration
sysproxy get Wi-Fi

# Output in JSON format
sysproxy get Wi-Fi --json
```

### Output Example

```
Proxy Configuration for 'Wi-Fi':
--------------------------------------------------

[Auto Discovery]
  Auto Proxy Discovery (WPAD): Disabled

[Automatic Proxy Configuration (PAC)]
  Status: Disabled

[HTTP Proxy]
  Status: Enabled
  Server: 127.0.0.1:7890

[HTTPS Proxy]
  Status: Enabled
  Server: 127.0.0.1:7890

[SOCKS Proxy]
  Status: Disabled

[Bypass Settings]
  Exclude Simple Hostnames: No
  Exception List:
    - *.local
    - 169.254/16
```

---

## set - Set Proxy Configuration

Set proxy configuration for a specified network interface. **Requires root privileges**.

```bash
sudo sysproxy set <TYPE> [OPTIONS]
```

### Proxy Types

| Type | Description |
|------|-------------|
| `http` | HTTP proxy |
| `https` | HTTPS proxy |
| `socks` | SOCKS proxy |
| `pac` | PAC auto-configuration |

---

### set http - Set HTTP Proxy

```bash
sudo sysproxy set http --host <HOST> --port <PORT> --interface <INTERFACE> [OPTIONS]
```

#### Options

| Option | Description |
|--------|-------------|
| `-h, --host` | Proxy server host (required) |
| `-p, --port` | Proxy server port (required) |
| `-i, --interface` | Network interface name (required) |
| `--username` | Authentication username (optional) |
| `--password` | Authentication password (optional) |
| `--with-https` | Also set HTTPS proxy with the same settings |

#### Examples

```bash
# Set HTTP proxy
sudo sysproxy set http --host 127.0.0.1 --port 7890 --interface Wi-Fi

# Set both HTTP and HTTPS proxy
sudo sysproxy set http --host 127.0.0.1 --port 7890 --interface Wi-Fi --with-https

# Set proxy with authentication
sudo sysproxy set http --host proxy.example.com --port 8080 --interface Wi-Fi \
    --username user --password pass
```

---

### set https - Set HTTPS Proxy

```bash
sudo sysproxy set https --host <HOST> --port <PORT> --interface <INTERFACE> [OPTIONS]
```

#### Options

Same as `set http` (excluding `--with-https`).

#### Examples

```bash
sudo sysproxy set https --host 127.0.0.1 --port 7890 --interface Wi-Fi
```

---

### set socks - Set SOCKS Proxy

```bash
sudo sysproxy set socks --host <HOST> --port <PORT> --interface <INTERFACE> [OPTIONS]
```

#### Options

| Option | Description |
|--------|-------------|
| `-h, --host` | Proxy server host (required) |
| `-p, --port` | Proxy server port (required) |
| `-i, --interface` | Network interface name (required) |
| `--username` | Authentication username (optional) |
| `--password` | Authentication password (optional) |

#### Examples

```bash
# Set SOCKS5 proxy
sudo sysproxy set socks --host 127.0.0.1 --port 1080 --interface Wi-Fi
```

---

### set pac - Set PAC Auto-Configuration

```bash
sudo sysproxy set pac --url <URL> --interface <INTERFACE>
```

#### Options

| Option | Description |
|--------|-------------|
| `-u, --url` | PAC script URL (required) |
| `-i, --interface` | Network interface name (required) |

#### Examples

```bash
sudo sysproxy set pac --url "http://example.com/proxy.pac" --interface Wi-Fi
```

---

## disable - Disable Proxies

Disable all proxy settings for a specified network interface. **Requires root privileges**.

```bash
sudo sysproxy disable <INTERFACE>
sudo sysproxy disable --all
```

### Arguments

| Argument | Description |
|----------|-------------|
| `<INTERFACE>` | Network interface name |

### Options

| Option | Description |
|--------|-------------|
| `-a, --all` | Disable proxies for all enabled network services |

### Examples

```bash
# Disable all proxies for Wi-Fi
sudo sysproxy disable Wi-Fi

# Disable proxies for all services
sudo sysproxy disable --all
```

---

## Common Use Cases

### Use Case 1: Quick Enable/Disable Proxy

```bash
# Enable HTTP/HTTPS proxy (Clash/V2Ray, etc.)
sudo sysproxy set http --host 127.0.0.1 --port 7890 --interface Wi-Fi --with-https

# Disable proxy
sudo sysproxy disable Wi-Fi
```

### Use Case 2: Using SOCKS5 Proxy

```bash
# Set SOCKS5 proxy (SSH tunnel, etc.)
sudo sysproxy set socks --host 127.0.0.1 --port 1080 --interface Wi-Fi
```

### Use Case 3: Using PAC File

```bash
# Use company-provided PAC file
sudo sysproxy set pac --url "http://wpad.company.com/proxy.pac" --interface Wi-Fi
```

### Use Case 4: Script Automation

```bash
#!/bin/bash
# Automatically set proxy after VPN connection
INTERFACE="Wi-Fi"
PROXY_HOST="10.0.0.1"
PROXY_PORT="8080"

# Backup current configuration
sysproxy get "$INTERFACE" --json > /tmp/proxy_backup.json

# Set proxy
sudo sysproxy set http --host "$PROXY_HOST" --port "$PROXY_PORT" --interface "$INTERFACE" --with-https

# Restore when done
# sudo sysproxy disable "$INTERFACE"
```

---

## Troubleshooting

### Permission Denied

```
Error: Operation not permitted
```

**Solution**: Use `sudo` for commands that modify system settings.

### Network Service Not Found

```
Error: Service not found: "WiFi"
```

**Solution**: Use `sysproxy list` to check the correct service name. Note that names are case-sensitive, e.g., `Wi-Fi` not `WiFi`.

### Proxy Settings Not Applied

**Solutions**:
1. Check if proxy server is running
2. Open System Preferences → Network → Select interface → Advanced → Proxies to verify settings
3. Try restarting network services or browser

---

## Getting Help

```bash
# View main command help
sysproxy --help

# View subcommand help
sysproxy get --help
sysproxy set --help
sysproxy set http --help

# View version
sysproxy --version
```
