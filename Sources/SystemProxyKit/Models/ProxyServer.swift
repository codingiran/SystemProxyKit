//
//  ProxyServer.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// Represents a single proxy server node with optional authentication
public struct ProxyServer: Equatable, Hashable, Sendable, Codable {
    /// Hostname or IP address
    public let host: String

    /// Port number
    public let port: Int

    /// Enable/disable state
    public var isEnabled: Bool

    /// Authentication username (optional)
    public let username: String?

    /// Authentication password (optional, should be stored securely in Keychain)
    public let password: String?

    /// Initializes a proxy server configuration
    /// - Parameters:
    ///   - host: Hostname or IP address
    ///   - port: Port number
    ///   - isEnabled: Enable/disable state, defaults to true
    ///   - username: Authentication username (optional)
    ///   - password: Authentication password (optional)
    public init(
        host: String,
        port: Int,
        isEnabled: Bool = true,
        username: String? = nil,
        password: String? = nil
    ) {
        self.host = host
        self.port = port
        self.isEnabled = isEnabled
        self.username = username
        self.password = password
    }

    /// Whether authentication credentials are configured
    public var hasAuthentication: Bool {
        username != nil && password != nil
    }
}

// MARK: - CustomStringConvertible

extension ProxyServer: CustomStringConvertible {
    public var description: String {
        let auth = hasAuthentication ? " (authenticated)" : ""
        let status = isEnabled ? "enabled" : "disabled"
        return "ProxyServer(\(host):\(port), \(status)\(auth))"
    }
}
