# SystemProxyKit

[中文文档](./README_ZH.md)

A Swift Package for managing macOS system network proxy settings with a type-safe, modern API.

## Features

- **Type-Safe Configuration**: Pure Swift models with no raw dictionary manipulation
- **Full Proxy Support**: HTTP, HTTPS, SOCKS, and PAC auto-configuration
- **Swift Concurrency**: Modern `async/await` API built on actors
- **Thread-Safe**: All operations are concurrency-safe
- **Retry Strategy**: Configurable retry policies for reliability
- **Snapshot & Rollback**: Easy backup and restore of proxy settings

## Requirements

- macOS 10.15+
- Swift 5.10+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add SystemProxyKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOURUSERNAME/SystemProxyKit.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select version and add to your target

## Quick Start

### Reading Proxy Configuration

```swift
import SystemProxyKit

// Get current proxy settings
let config = try await SystemProxyKit.current(for: "Wi-Fi")
print(config)
```

### Setting HTTP Proxy

```swift
// Quick method
try await SystemProxyKit.setHTTPProxy(
    host: "127.0.0.1",
    port: 7890,
    for: "Wi-Fi"
)

// Or configure manually
var config = try await SystemProxyKit.current(for: "Wi-Fi")
config.httpProxy = ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true)
config.httpsProxy = ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true)
try await SystemProxyKit.setProxy(config, for: "Wi-Fi")
```

### PAC Configuration

```swift
let pacURL = URL(string: "http://example.com/proxy.pac")!
try await SystemProxyKit.setPACProxy(url: pacURL, for: "Wi-Fi")
```

### Safe Modification Pattern

```swift
// 1. Backup original settings
let original = try await SystemProxyKit.current(for: "Wi-Fi")

// 2. Apply new configuration
try await SystemProxyKit.setHTTPProxy(host: "127.0.0.1", port: 7890, for: "Wi-Fi")

// 3. Do your work...

// 4. Restore when done
try await SystemProxyKit.setProxy(original, for: "Wi-Fi")
```

## API Overview

### Core Types

- **`ProxyConfiguration`**: Complete proxy settings for a network interface
- **`ProxyServer`**: Individual proxy server with optional authentication
- **`PACConfiguration`**: PAC (Proxy Auto-Configuration) settings
- **`RetryPolicy`**: Configurable retry strategy

### Main APIs

```swift
// Get proxy configuration
func current(for interface: String) async throws -> ProxyConfiguration

// Set proxy configuration
func setProxy(_ config: ProxyConfiguration, for interface: String) async throws

// List network services
func availableServices() async throws -> [String]

// Disable all proxies
func disableAllProxies(for interface: String) async throws
```

## Permissions

### Reading
No special permissions required for reading proxy settings.

### Writing
Modifying system proxy settings requires administrator privileges:

```bash
# Run with sudo if your app doesn't have elevated privileges
sudo your-app
```

Or provide an `AuthorizationRef` when creating `SystemProxyManager`.

## Testing

The project includes comprehensive tests:

```bash
# Run unit and integration tests (read-only)
swift test

# Run privileged tests (requires sudo, modifies system settings)
sudo swift test --filter Privileged
```

**Note**: Privileged tests will temporarily modify your system proxy settings but automatically restore them after completion.

## Architecture

SystemProxyKit follows a layered architecture:

- **Models**: Pure Swift data structures
- **Mapping**: Conversion between Swift models and SystemConfiguration dictionaries
- **Core**: Business logic and system interaction
- **Utils**: Error definitions and constants
- **Interface**: Public API entry point

See [Implement_en.md](./Implement_en.md) for detailed technical design.

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

[Your Name](https://github.com/YOURUSERNAME)
