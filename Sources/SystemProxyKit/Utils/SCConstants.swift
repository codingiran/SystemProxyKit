//
//  SCConstants.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation
import SystemConfiguration

/// SystemConfiguration proxy-related constants
/// These constants are used for interacting with SCNetworkProtocol dictionaries
public enum SCProxyKeys {
    // MARK: - HTTP Proxy

    /// HTTP proxy enable/disable state (CFNumber: 0 or 1)
    public static let httpEnable = kSCPropNetProxiesHTTPEnable as String

    /// HTTP proxy host (CFString)
    public static let httpProxy = kSCPropNetProxiesHTTPProxy as String

    /// HTTP proxy port (CFNumber)
    public static let httpPort = kSCPropNetProxiesHTTPPort as String

    // MARK: - HTTPS Proxy

    /// HTTPS proxy enable/disable state (CFNumber: 0 or 1)
    public static let httpsEnable = kSCPropNetProxiesHTTPSEnable as String

    /// HTTPS proxy host (CFString)
    public static let httpsProxy = kSCPropNetProxiesHTTPSProxy as String

    /// HTTPS proxy port (CFNumber)
    public static let httpsPort = kSCPropNetProxiesHTTPSPort as String

    // MARK: - SOCKS Proxy

    /// SOCKS proxy enable/disable state (CFNumber: 0 or 1)
    public static let socksEnable = kSCPropNetProxiesSOCKSEnable as String

    /// SOCKS proxy host (CFString)
    public static let socksProxy = kSCPropNetProxiesSOCKSProxy as String

    /// SOCKS proxy port (CFNumber)
    public static let socksPort = kSCPropNetProxiesSOCKSPort as String

    // MARK: - PAC (Proxy Auto-Configuration)

    /// PAC auto proxy configuration enable/disable state (CFNumber: 0 or 1)
    public static let proxyAutoConfigEnable = kSCPropNetProxiesProxyAutoConfigEnable as String

    /// PAC script URL (CFString)
    public static let proxyAutoConfigURLString = kSCPropNetProxiesProxyAutoConfigURLString as String

    // MARK: - Auto Discovery (WPAD)

    /// Auto-discover proxy enable/disable state (CFNumber: 0 or 1)
    public static let proxyAutoDiscoveryEnable = kSCPropNetProxiesProxyAutoDiscoveryEnable as String

    // MARK: - Exceptions

    /// Exception host list (CFArray of CFString)
    public static let exceptionsList = kSCPropNetProxiesExceptionsList as String

    /// Exclude simple hostnames (CFNumber: 0 or 1)
    public static let excludeSimpleHostnames = kSCPropNetProxiesExcludeSimpleHostnames as String
}

/// Protocol type constants
public enum SCProtocolType {
    /// Proxies protocol type
    public static let proxies = kSCNetworkProtocolTypeProxies as String
}

/// Helper extension: Convert Swift Bool to CFNumber format (0 or 1)
extension Bool {
    /// Converts to numeric format used by SystemConfiguration
    var asCFNumber: Int { self ? 1 : 0 }
}

/// Helper extension: Safely extract boolean value from Any type
extension Dictionary where Key == String, Value == Any {
    /// Safely retrieves boolean value (handles CFNumber 0/1 format)
    func getBool(forKey key: String) -> Bool {
        if let number = self[key] as? Int {
            return number != 0
        }
        if let number = self[key] as? NSNumber {
            return number.boolValue
        }
        return false
    }

    /// Safely retrieves string value
    func getString(forKey key: String) -> String? {
        self[key] as? String
    }

    /// Safely retrieves integer value
    func getInt(forKey key: String) -> Int? {
        if let number = self[key] as? Int {
            return number
        }
        if let number = self[key] as? NSNumber {
            return number.intValue
        }
        return nil
    }

    /// Safely retrieves string array
    func getStringArray(forKey key: String) -> [String] {
        self[key] as? [String] ?? []
    }
}
