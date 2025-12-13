# SystemProxyKit

[English](./README.md)

一个用于管理 macOS 系统网络代理设置的 Swift Package，提供类型安全的现代化 API。

## 特性

- **类型安全配置**：纯 Swift 模型，无需操作原始字典
- **全面的代理支持**：HTTP、HTTPS、SOCKS 和 PAC 自动配置
- **Swift 并发**：基于 actor 的现代 `async/await` API
- **线程安全**：所有操作都是并发安全的
- **重试策略**：可配置的重试策略以提高可靠性
- **快照与回滚**：轻松备份和恢复代理设置

## 系统要求

- macOS 10.15+
- Swift 5.10+
- Xcode 14.0+

## 安装

### Swift Package Manager

在 `Package.swift` 中添加 SystemProxyKit：

```swift
dependencies: [
    .package(url: "https://github.com/codingiran/SystemProxyKit.git", from: "1.0.0")
]
```

或通过 Xcode 添加：
1. File → Add Package Dependencies
2. 输入仓库 URL
3. 选择版本并添加到目标

## 快速开始

### 读取代理配置

```swift
import SystemProxyKit

// 获取单个接口的代理设置
let config = try await SystemProxyKit.getProxy(for: "Wi-Fi")
print(config)

// 批量获取多个接口的代理配置
let configs = try await SystemProxyKit.getProxy(for: ["Wi-Fi", "Ethernet"])
for (interface, config) in configs {
    print("\(interface): \(config)")
}
```

### 设置 HTTP 代理

```swift
// 单个接口的快捷方法
try await SystemProxyKit.setHTTPProxy(
    host: "127.0.0.1",
    port: 7890,
    for: "Wi-Fi"
)

// 或手动配置
var config = try await SystemProxyKit.getProxy(for: "Wi-Fi")
config.httpProxy = ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true)
config.httpsProxy = ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true)
try await SystemProxyKit.setProxy(config, for: "Wi-Fi")
```

### 批量代理配置

```swift
// 为多个接口设置相同的代理（单次 commit/apply，效率更高）
var config = ProxyConfiguration()
config.httpProxy = ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true)

let result = try await SystemProxyKit.setProxy(config, for: ["Wi-Fi", "Ethernet", "Thunderbolt Bridge"])
print("成功: \(result.succeeded), 失败: \(result.failed.count)")

// 或为所有启用的服务设置代理
let result = try await SystemProxyKit.setProxyForAllEnabledServices(config)
```

### PAC 配置

```swift
let pacURL = URL(string: "http://example.com/proxy.pac")!
try await SystemProxyKit.setPACProxy(url: pacURL, for: "Wi-Fi")
```

### 安全修改模式

```swift
// 1. 备份原始设置
let original = try await SystemProxyKit.getProxy(for: "Wi-Fi")

// 2. 应用新配置
try await SystemProxyKit.setHTTPProxy(host: "127.0.0.1", port: 7890, for: "Wi-Fi")

// 3. 执行你的工作...

// 4. 完成后恢复
try await SystemProxyKit.setProxy(original, for: "Wi-Fi")
```

## API 概览

### 核心类型

- **`ProxyConfiguration`**：网络接口的完整代理设置
- **`ProxyServer`**：单个代理服务器，支持可选认证
- **`PACConfiguration`**：PAC（代理自动配置）设置
- **`BatchProxyResult`**：批量操作结果，包含成功/失败列表
- **`RetryPolicy`**：可配置的重试策略（默认：不重试）

### 主要 API

```swift
// 获取代理配置（单个或批量）
func getProxy(for interface: String) async throws -> ProxyConfiguration
func getProxy(for interfaces: [String]) async throws -> [(interface: String, config: ProxyConfiguration)]

// 设置代理配置（单个或批量）
func setProxy(_ config: ProxyConfiguration, for interface: String) async throws
func setProxy(_ config: ProxyConfiguration, for interfaces: [String]) async throws -> BatchProxyResult
func setProxy(configurations: [(interface: String, config: ProxyConfiguration)]) async throws -> BatchProxyResult
func setProxyForAllEnabledServices(_ config: ProxyConfiguration) async throws -> BatchProxyResult

// 列出网络服务
func availableServices() async throws -> [String]
func allServicesInfo() async throws -> [ServiceInfo]

// 禁用所有代理
func disableAllProxies(for interface: String) async throws
```

## 权限要求

### 读取
读取代理设置无需特殊权限。

### 写入
修改系统代理设置需要管理员权限：

```bash
# 如果应用没有提升权限，使用 sudo 运行
sudo your-app
```

或在创建 `SystemProxyManager` 时提供 `AuthorizationRef`。

## 测试

项目包含全面的测试：

```bash
# 运行单元测试和集成测试（只读）
swift test

# 运行特权测试（需要 sudo，会修改系统设置）
sudo swift test --filter Privileged
```

**注意**：特权测试会临时修改系统代理设置，但完成后会自动恢复。

## 架构

SystemProxyKit 采用分层架构：

- **Models**：纯 Swift 数据结构
- **Mapping**：Swift 模型与 SystemConfiguration 字典的转换
- **Core**：业务逻辑和系统交互
- **Utils**：错误定义和常量
- **Interface**：公共 API 入口

详细技术设计请参阅 [Implement.md](./Implement.md)。

## 许可证

MIT License - 详见 [LICENSE](./LICENSE)

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 作者

[CodingIran](https://github.com/CodingIran)
