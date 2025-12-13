//
//  ProxyConfiguration.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// 描述完整的网络服务代理配置
public struct ProxyConfiguration: Equatable, Sendable, Codable {
    // MARK: - Automatic Proxy

    /// 自动发现代理 (WPAD)
    public var autoDiscoveryEnabled: Bool

    /// 自动代理配置 (PAC)
    public var autoConfigURL: PACConfiguration?

    // MARK: - Manual Proxy

    /// 网页代理 (HTTP)
    public var httpProxy: ProxyServer?

    /// 安全网页代理 (HTTPS)
    public var httpsProxy: ProxyServer?

    /// SOCKS 代理
    public var socksProxy: ProxyServer?

    // MARK: - Exceptions

    /// 不包括简单主机名
    public var excludeSimpleHostnames: Bool

    /// 忽略的主机与域列表
    public var exceptionList: [String]

    // MARK: - Initialization

    /// 初始化完整代理配置
    /// - Parameters:
    ///   - autoDiscoveryEnabled: 自动发现代理开关
    ///   - autoConfigURL: PAC 配置
    ///   - httpProxy: HTTP 代理配置
    ///   - httpsProxy: HTTPS 代理配置
    ///   - socksProxy: SOCKS 代理配置
    ///   - excludeSimpleHostnames: 是否排除简单主机名
    ///   - exceptionList: 例外主机列表
    public init(
        autoDiscoveryEnabled: Bool = false,
        autoConfigURL: PACConfiguration? = nil,
        httpProxy: ProxyServer? = nil,
        httpsProxy: ProxyServer? = nil,
        socksProxy: ProxyServer? = nil,
        excludeSimpleHostnames: Bool = false,
        exceptionList: [String] = []
    ) {
        self.autoDiscoveryEnabled = autoDiscoveryEnabled
        self.autoConfigURL = autoConfigURL
        self.httpProxy = httpProxy
        self.httpsProxy = httpsProxy
        self.socksProxy = socksProxy
        self.excludeSimpleHostnames = excludeSimpleHostnames
        self.exceptionList = exceptionList
    }

    /// 创建一个空的代理配置（所有代理都禁用）
    public static var empty: ProxyConfiguration {
        ProxyConfiguration()
    }
}

// MARK: - Convenience Methods

public extension ProxyConfiguration {
    /// 是否有任何手动代理启用
    var hasManualProxyEnabled: Bool {
        (httpProxy?.isEnabled ?? false) ||
            (httpsProxy?.isEnabled ?? false) ||
            (socksProxy?.isEnabled ?? false)
    }

    /// 是否有任何自动代理启用
    var hasAutoProxyEnabled: Bool {
        autoDiscoveryEnabled || (autoConfigURL?.isEnabled ?? false)
    }

    /// 是否有任何代理配置启用
    var hasAnyProxyEnabled: Bool {
        hasManualProxyEnabled || hasAutoProxyEnabled
    }

    /// 禁用所有代理
    mutating func disableAllProxies() {
        autoDiscoveryEnabled = false
        autoConfigURL?.isEnabled = false
        httpProxy?.isEnabled = false
        httpsProxy?.isEnabled = false
        socksProxy?.isEnabled = false
    }
}

// MARK: - CustomStringConvertible

extension ProxyConfiguration: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []

        if autoDiscoveryEnabled {
            parts.append("WPAD: enabled")
        }
        if let pac = autoConfigURL, pac.isEnabled {
            parts.append("PAC: \(pac.url.absoluteString)")
        }
        if let http = httpProxy, http.isEnabled {
            parts.append("HTTP: \(http.host):\(http.port)")
        }
        if let https = httpsProxy, https.isEnabled {
            parts.append("HTTPS: \(https.host):\(https.port)")
        }
        if let socks = socksProxy, socks.isEnabled {
            parts.append("SOCKS: \(socks.host):\(socks.port)")
        }

        if parts.isEmpty {
            return "ProxyConfiguration(no proxy enabled)"
        }

        return "ProxyConfiguration(\(parts.joined(separator: ", ")))"
    }
}
