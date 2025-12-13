//
//  ProxyConfiguration.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// Complete network service proxy configuration
public struct ProxyConfiguration: Equatable, Sendable, Codable {
    // MARK: - Automatic Proxy

    /// Auto-discover proxy (WPAD)
    public var autoDiscoveryEnabled: Bool

    /// Automatic proxy configuration (PAC)
    public var autoConfigURL: PACConfiguration?

    // MARK: - Manual Proxy

    /// Web proxy (HTTP)
    public var httpProxy: ProxyServer?

    /// Secure web proxy (HTTPS)
    public var httpsProxy: ProxyServer?

    /// SOCKS proxy
    public var socksProxy: ProxyServer?

    // MARK: - Exceptions

    /// Exclude simple hostnames
    public var excludeSimpleHostnames: Bool

    /// Bypass proxy for these hosts and domains
    public var exceptionList: [String]

    // MARK: - Initialization

    /// Initializes complete proxy configuration
    /// - Parameters:
    ///   - autoDiscoveryEnabled: Auto-discover proxy toggle
    ///   - autoConfigURL: PAC configuration
    ///   - httpProxy: HTTP proxy configuration
    ///   - httpsProxy: HTTPS proxy configuration
    ///   - socksProxy: SOCKS proxy configuration
    ///   - excludeSimpleHostnames: Whether to exclude simple hostnames
    ///   - exceptionList: Exception host list
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

    /// Creates an empty proxy configuration (all proxies disabled)
    public static var empty: ProxyConfiguration {
        ProxyConfiguration()
    }
}

// MARK: - Convenience Methods

public extension ProxyConfiguration {
    /// Whether any manual proxy is enabled
    var hasManualProxyEnabled: Bool {
        (httpProxy?.isEnabled ?? false) ||
            (httpsProxy?.isEnabled ?? false) ||
            (socksProxy?.isEnabled ?? false)
    }

    /// Whether any automatic proxy is enabled
    var hasAutoProxyEnabled: Bool {
        autoDiscoveryEnabled || (autoConfigURL?.isEnabled ?? false)
    }

    /// Whether any proxy configuration is enabled
    var hasAnyProxyEnabled: Bool {
        hasManualProxyEnabled || hasAutoProxyEnabled
    }

    /// Disables all proxies
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
