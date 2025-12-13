//
//  SCConstants.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation
import SystemConfiguration

/// SystemConfiguration 代理相关常量
/// 这些常量用于与 SCNetworkProtocol 字典交互
public enum SCProxyKeys {
    // MARK: - HTTP Proxy

    /// HTTP 代理开关 (CFNumber: 0 or 1)
    public static let httpEnable = kSCPropNetProxiesHTTPEnable as String

    /// HTTP 代理主机 (CFString)
    public static let httpProxy = kSCPropNetProxiesHTTPProxy as String

    /// HTTP 代理端口 (CFNumber)
    public static let httpPort = kSCPropNetProxiesHTTPPort as String

    // MARK: - HTTPS Proxy

    /// HTTPS 代理开关 (CFNumber: 0 or 1)
    public static let httpsEnable = kSCPropNetProxiesHTTPSEnable as String

    /// HTTPS 代理主机 (CFString)
    public static let httpsProxy = kSCPropNetProxiesHTTPSProxy as String

    /// HTTPS 代理端口 (CFNumber)
    public static let httpsPort = kSCPropNetProxiesHTTPSPort as String

    // MARK: - SOCKS Proxy

    /// SOCKS 代理开关 (CFNumber: 0 or 1)
    public static let socksEnable = kSCPropNetProxiesSOCKSEnable as String

    /// SOCKS 代理主机 (CFString)
    public static let socksProxy = kSCPropNetProxiesSOCKSProxy as String

    /// SOCKS 代理端口 (CFNumber)
    public static let socksPort = kSCPropNetProxiesSOCKSPort as String

    // MARK: - PAC (Proxy Auto-Configuration)

    /// PAC 自动代理配置开关 (CFNumber: 0 or 1)
    public static let proxyAutoConfigEnable = kSCPropNetProxiesProxyAutoConfigEnable as String

    /// PAC URL (CFString)
    public static let proxyAutoConfigURLString = kSCPropNetProxiesProxyAutoConfigURLString as String

    // MARK: - Auto Discovery (WPAD)

    /// 自动发现代理开关 (CFNumber: 0 or 1)
    public static let proxyAutoDiscoveryEnable = kSCPropNetProxiesProxyAutoDiscoveryEnable as String

    // MARK: - Exceptions

    /// 例外主机列表 (CFArray of CFString)
    public static let exceptionsList = kSCPropNetProxiesExceptionsList as String

    /// 排除简单主机名 (CFNumber: 0 or 1)
    public static let excludeSimpleHostnames = kSCPropNetProxiesExcludeSimpleHostnames as String
}

/// 协议类型常量
public enum SCProtocolType {
    /// 代理协议类型
    public static let proxies = kSCNetworkProtocolTypeProxies as String
}

/// 辅助扩展：将 Swift Bool 转换为 CFNumber 格式 (0 or 1)
extension Bool {
    /// 转换为 SystemConfiguration 使用的数字格式
    var asCFNumber: Int { self ? 1 : 0 }
}

/// 辅助扩展：从 Any 类型安全提取布尔值
extension Dictionary where Key == String, Value == Any {
    /// 安全获取布尔值（处理 CFNumber 0/1 格式）
    func getBool(forKey key: String) -> Bool {
        if let number = self[key] as? Int {
            return number != 0
        }
        if let number = self[key] as? NSNumber {
            return number.boolValue
        }
        return false
    }

    /// 安全获取字符串值
    func getString(forKey key: String) -> String? {
        self[key] as? String
    }

    /// 安全获取整数值
    func getInt(forKey key: String) -> Int? {
        if let number = self[key] as? Int {
            return number
        }
        if let number = self[key] as? NSNumber {
            return number.intValue
        }
        return nil
    }

    /// 安全获取字符串数组
    func getStringArray(forKey key: String) -> [String] {
        self[key] as? [String] ?? []
    }
}
