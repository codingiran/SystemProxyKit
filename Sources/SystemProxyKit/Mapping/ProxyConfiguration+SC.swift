//
//  ProxyConfiguration+SC.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation
import SystemConfiguration

// MARK: - Deserialization (Dictionary -> Model)

public extension ProxyConfiguration {
    /// Creates ProxyConfiguration from dictionary returned by SCNetworkProtocol
    /// - Parameter dictionary: Proxy configuration dictionary
    /// - Returns: ProxyConfiguration instance
    init(fromSCDictionary dictionary: [String: Any]) {
        // Auto Discovery (WPAD)
        autoDiscoveryEnabled = dictionary.getBool(forKey: SCProxyKeys.proxyAutoDiscoveryEnable)

        // PAC Configuration
        let pacEnabled = dictionary.getBool(forKey: SCProxyKeys.proxyAutoConfigEnable)
        if let pacURLString = dictionary.getString(forKey: SCProxyKeys.proxyAutoConfigURLString),
           let pacURL = URL(string: pacURLString)
        {
            autoConfigURL = PACConfiguration(url: pacURL, isEnabled: pacEnabled)
        } else {
            autoConfigURL = nil
        }

        // HTTP Proxy
        let httpEnabled = dictionary.getBool(forKey: SCProxyKeys.httpEnable)
        if let httpHost = dictionary.getString(forKey: SCProxyKeys.httpProxy),
           let httpPort = dictionary.getInt(forKey: SCProxyKeys.httpPort)
        {
            httpProxy = ProxyServer(
                host: httpHost,
                port: httpPort,
                isEnabled: httpEnabled
            )
        } else {
            httpProxy = nil
        }

        // HTTPS Proxy
        let httpsEnabled = dictionary.getBool(forKey: SCProxyKeys.httpsEnable)
        if let httpsHost = dictionary.getString(forKey: SCProxyKeys.httpsProxy),
           let httpsPort = dictionary.getInt(forKey: SCProxyKeys.httpsPort)
        {
            httpsProxy = ProxyServer(
                host: httpsHost,
                port: httpsPort,
                isEnabled: httpsEnabled
            )
        } else {
            httpsProxy = nil
        }

        // SOCKS Proxy
        let socksEnabled = dictionary.getBool(forKey: SCProxyKeys.socksEnable)
        if let socksHost = dictionary.getString(forKey: SCProxyKeys.socksProxy),
           let socksPort = dictionary.getInt(forKey: SCProxyKeys.socksPort)
        {
            socksProxy = ProxyServer(
                host: socksHost,
                port: socksPort,
                isEnabled: socksEnabled
            )
        } else {
            socksProxy = nil
        }

        // Exceptions
        excludeSimpleHostnames = dictionary.getBool(forKey: SCProxyKeys.excludeSimpleHostnames)
        exceptionList = dictionary.getStringArray(forKey: SCProxyKeys.exceptionsList)
    }
}

// MARK: - Serialization (Model -> Dictionary)

public extension ProxyConfiguration {
    /// Converts ProxyConfiguration to dictionary accepted by SCNetworkProtocol
    /// - Returns: Proxy configuration dictionary
    func toSCDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]

        // Auto Discovery (WPAD)
        dict[SCProxyKeys.proxyAutoDiscoveryEnable] = autoDiscoveryEnabled.asCFNumber

        // PAC Configuration
        if let pac = autoConfigURL {
            dict[SCProxyKeys.proxyAutoConfigEnable] = pac.isEnabled.asCFNumber
            dict[SCProxyKeys.proxyAutoConfigURLString] = pac.url.absoluteString
        } else {
            dict[SCProxyKeys.proxyAutoConfigEnable] = false.asCFNumber
        }

        // HTTP Proxy
        if let http = httpProxy {
            dict[SCProxyKeys.httpEnable] = http.isEnabled.asCFNumber
            dict[SCProxyKeys.httpProxy] = http.host
            dict[SCProxyKeys.httpPort] = http.port
        } else {
            dict[SCProxyKeys.httpEnable] = false.asCFNumber
        }

        // HTTPS Proxy
        if let https = httpsProxy {
            dict[SCProxyKeys.httpsEnable] = https.isEnabled.asCFNumber
            dict[SCProxyKeys.httpsProxy] = https.host
            dict[SCProxyKeys.httpsPort] = https.port
        } else {
            dict[SCProxyKeys.httpsEnable] = false.asCFNumber
        }

        // SOCKS Proxy
        if let socks = socksProxy {
            dict[SCProxyKeys.socksEnable] = socks.isEnabled.asCFNumber
            dict[SCProxyKeys.socksProxy] = socks.host
            dict[SCProxyKeys.socksPort] = socks.port
        } else {
            dict[SCProxyKeys.socksEnable] = false.asCFNumber
        }

        // Exceptions
        dict[SCProxyKeys.excludeSimpleHostnames] = excludeSimpleHostnames.asCFNumber
        if !exceptionList.isEmpty {
            dict[SCProxyKeys.exceptionsList] = exceptionList
        }

        return dict
    }
}

// MARK: - Merge Support

public extension ProxyConfiguration {
    /// Merges current configuration with existing dictionary
    /// Used to preserve other configuration keys while only updating proxy-related settings
    /// - Parameter existingDict: Existing configuration dictionary
    /// - Returns: Merged dictionary
    func mergeIntoSCDictionary(_ existingDict: [String: Any]) -> [String: Any] {
        var merged = existingDict
        let proxyDict = toSCDictionary()

        for (key, value) in proxyDict {
            merged[key] = value
        }

        return merged
    }
}
