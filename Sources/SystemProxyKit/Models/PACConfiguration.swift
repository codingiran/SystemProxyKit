//
//  PACConfiguration.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// Represents PAC (Proxy Auto-Configuration) settings
public struct PACConfiguration: Equatable, Hashable, Sendable, Codable {
    /// URL of the PAC script
    public let url: URL

    /// Enable/disable state
    public var isEnabled: Bool

    /// Initializes PAC configuration
    /// - Parameters:
    ///   - url: URL of the PAC script
    ///   - isEnabled: Enable/disable state, defaults to true
    public init(url: URL, isEnabled: Bool = true) {
        self.url = url
        self.isEnabled = isEnabled
    }

    /// Initializes from URL string
    /// - Parameters:
    ///   - urlString: URL string of the PAC script
    ///   - isEnabled: Enable/disable state, defaults to true
    /// - Returns: `nil` if URL is invalid
    public init?(urlString: String, isEnabled: Bool = true) {
        guard let url = URL(string: urlString) else {
            return nil
        }
        self.url = url
        self.isEnabled = isEnabled
    }
}

// MARK: - CustomStringConvertible

extension PACConfiguration: CustomStringConvertible {
    public var description: String {
        let status = isEnabled ? "enabled" : "disabled"
        return "PACConfiguration(\(url.absoluteString), \(status))"
    }
}
