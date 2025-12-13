# sysproxy CLI 操作指南

`sysproxy` 是 SystemProxyKit 提供的命令行工具，用于管理 macOS 系统代理设置。

## 安装与运行

### 开发环境
```bash
cd /path/to/SystemProxyKit
swift run sysproxy [command]
```

### 构建安装
```bash
swift build -c release
sudo cp .build/release/sysproxy /usr/local/bin/
sysproxy [command]
```

---

## 命令概览

| 命令 | 说明 | 需要 Root |
|------|------|:---------:|
| `list` | 列出所有网络服务 | ❌ |
| `get` | 获取代理配置 | ❌ |
| `set` | 设置代理 | ✅ |
| `disable` | 禁用代理 | ✅ |

---

## list - 列出网络服务

列出系统中所有可用的网络服务。

```bash
sysproxy list [OPTIONS]
```

### 选项

| 选项 | 说明 |
|------|------|
| `-e, --enabled-only` | 仅显示已启用的服务 |
| `-v, --verbose` | 显示详细信息 |

### 示例

```bash
# 列出所有服务
sysproxy list

# 仅列出已启用的服务
sysproxy list --enabled-only

# 显示详细信息
sysproxy list --verbose
```

### 输出示例

```
Available Network Services:
  ✓ Wi-Fi
  ✓ Ethernet
  ✗ VPN (Disabled)

Total: 3 service(s)
```

---

## get - 获取代理配置

获取指定网络接口的当前代理配置。

```bash
sysproxy get <INTERFACE> [OPTIONS]
```

### 参数

| 参数 | 说明 |
|------|------|
| `<INTERFACE>` | 网络接口名称，如 `Wi-Fi`、`Ethernet` |

### 选项

| 选项 | 说明 |
|------|------|
| `-j, --json` | 以 JSON 格式输出 |

### 示例

```bash
# 获取 Wi-Fi 的代理配置
sysproxy get Wi-Fi

# 以 JSON 格式输出
sysproxy get Wi-Fi --json
```

### 输出示例

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

## set - 设置代理

设置指定网络接口的代理配置。**需要 root 权限**。

```bash
sudo sysproxy set <TYPE> [OPTIONS]
```

### 代理类型

| 类型 | 说明 |
|------|------|
| `http` | HTTP 代理 |
| `https` | HTTPS 代理 |
| `socks` | SOCKS 代理 |
| `pac` | PAC 自动配置 |

---

### set http - 设置 HTTP 代理

```bash
sudo sysproxy set http --host <HOST> --port <PORT> --interface <INTERFACE> [OPTIONS]
```

#### 选项

| 选项 | 说明 |
|------|------|
| `-h, --host` | 代理服务器地址 (必需) |
| `-p, --port` | 代理服务器端口 (必需) |
| `-i, --interface` | 网络接口名称 (必需) |
| `--username` | 认证用户名 (可选) |
| `--password` | 认证密码 (可选) |
| `--with-https` | 同时设置 HTTPS 代理 |

#### 示例

```bash
# 设置 HTTP 代理
sudo sysproxy set http --host 127.0.0.1 --port 7890 --interface Wi-Fi

# 同时设置 HTTP 和 HTTPS 代理
sudo sysproxy set http --host 127.0.0.1 --port 7890 --interface Wi-Fi --with-https

# 带认证的代理
sudo sysproxy set http --host proxy.example.com --port 8080 --interface Wi-Fi \
    --username user --password pass
```

---

### set https - 设置 HTTPS 代理

```bash
sudo sysproxy set https --host <HOST> --port <PORT> --interface <INTERFACE> [OPTIONS]
```

#### 选项

与 `set http` 相同（不含 `--with-https`）。

#### 示例

```bash
sudo sysproxy set https --host 127.0.0.1 --port 7890 --interface Wi-Fi
```

---

### set socks - 设置 SOCKS 代理

```bash
sudo sysproxy set socks --host <HOST> --port <PORT> --interface <INTERFACE> [OPTIONS]
```

#### 选项

| 选项 | 说明 |
|------|------|
| `-h, --host` | 代理服务器地址 (必需) |
| `-p, --port` | 代理服务器端口 (必需) |
| `-i, --interface` | 网络接口名称 (必需) |
| `--username` | 认证用户名 (可选) |
| `--password` | 认证密码 (可选) |

#### 示例

```bash
# 设置 SOCKS5 代理
sudo sysproxy set socks --host 127.0.0.1 --port 1080 --interface Wi-Fi
```

---

### set pac - 设置 PAC 自动配置

```bash
sudo sysproxy set pac --url <URL> --interface <INTERFACE>
```

#### 选项

| 选项 | 说明 |
|------|------|
| `-u, --url` | PAC 脚本 URL (必需) |
| `-i, --interface` | 网络接口名称 (必需) |

#### 示例

```bash
sudo sysproxy set pac --url "http://example.com/proxy.pac" --interface Wi-Fi
```

---

## disable - 禁用代理

禁用指定网络接口的所有代理设置。**需要 root 权限**。

```bash
sudo sysproxy disable <INTERFACE>
sudo sysproxy disable --all
```

### 参数

| 参数 | 说明 |
|------|------|
| `<INTERFACE>` | 网络接口名称 |

### 选项

| 选项 | 说明 |
|------|------|
| `-a, --all` | 禁用所有已启用网络服务的代理 |

### 示例

```bash
# 禁用 Wi-Fi 的所有代理
sudo sysproxy disable Wi-Fi

# 禁用所有服务的代理
sudo sysproxy disable --all
```

---

## 常用场景

### 场景 1: 快速开启/关闭代理

```bash
# 开启 HTTP/HTTPS 代理 (Clash/V2Ray 等)
sudo sysproxy set http --host 127.0.0.1 --port 7890 --interface Wi-Fi --with-https

# 关闭代理
sudo sysproxy disable Wi-Fi
```

### 场景 2: 使用 SOCKS5 代理

```bash
# 设置 SOCKS5 代理 (适用于 SSH 隧道等)
sudo sysproxy set socks --host 127.0.0.1 --port 1080 --interface Wi-Fi
```

### 场景 3: 使用 PAC 文件

```bash
# 使用公司提供的 PAC 文件
sudo sysproxy set pac --url "http://wpad.company.com/proxy.pac" --interface Wi-Fi
```

### 场景 4: 脚本自动化

```bash
#!/bin/bash
# 连接 VPN 后自动设置代理
INTERFACE="Wi-Fi"
PROXY_HOST="10.0.0.1"
PROXY_PORT="8080"

# 备份当前配置
sysproxy get "$INTERFACE" --json > /tmp/proxy_backup.json

# 设置代理
sudo sysproxy set http --host "$PROXY_HOST" --port "$PROXY_PORT" --interface "$INTERFACE" --with-https

# 工作完成后恢复
# sudo sysproxy disable "$INTERFACE"
```

---

## 故障排除

### 权限不足

```
Error: Operation not permitted
```

**解决方案**: 使用 `sudo` 运行需要修改系统设置的命令。

### 找不到网络服务

```
Error: Service not found: "WiFi"
```

**解决方案**: 使用 `sysproxy list` 查看正确的服务名称。注意名称区分大小写，如 `Wi-Fi` 而非 `WiFi`。

### 代理设置未生效

**解决方案**:
1. 检查代理服务器是否正常运行
2. 打开系统偏好设置 → 网络 → 选择接口 → 高级 → 代理，验证设置是否正确
3. 尝试重启网络服务或浏览器

---

## 获取帮助

```bash
# 查看主命令帮助
sysproxy --help

# 查看子命令帮助
sysproxy get --help
sysproxy set --help
sysproxy set http --help

# 查看版本
sysproxy --version
```
