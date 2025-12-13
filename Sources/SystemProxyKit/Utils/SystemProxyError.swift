//
//  SystemProxyError.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// SystemProxyKit error enumeration
public enum SystemProxyError: Error, Sendable {
    /// Failed to create SCPreferences (insufficient system resources or severe permission denial)
    case preferencesCreationFailed

    /// Failed to lock SCPreferences (another process is modifying network settings)
    case lockFailed

    /// Specified network service not found
    case serviceNotFound(name: String)

    /// Proxy protocol not found for the specified service
    case protocolNotFound(serviceName: String)

    /// Failed to retrieve proxy configuration
    case configurationNotFound(serviceName: String)

    /// Failed to write to system database
    case commitFailed

    /// Configuration written successfully but failed to apply
    case applyFailed

    /// Failed to unlock SCPreferences
    case unlockFailed

    /// Retry attempts exhausted
    case retryExhausted(lastErrorMessage: String)

    /// Invalid configuration parameters
    case invalidConfiguration(message: String)

    /// All operations in a batch failed
    case batchOperationFailed(errors: [(service: String, message: String)])

    /// Unknown error
    case unknown(message: String)
}

// MARK: - LocalizedError

extension SystemProxyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .preferencesCreationFailed:
            return "Failed to create system preferences session. Check app signing and permissions."
        case .lockFailed:
            return "Failed to lock system preferences. Another process may be modifying network settings."
        case let .serviceNotFound(name):
            return "Network service '\(name)' not found. Please check the interface name."
        case let .protocolNotFound(serviceName):
            return "Proxy protocol not found for service '\(serviceName)'."
        case let .configurationNotFound(serviceName):
            return "Proxy configuration not found for service '\(serviceName)'."
        case .commitFailed:
            return "Failed to commit changes to system database. Check for root permissions."
        case .applyFailed:
            return "Changes committed but failed to apply. Try restarting network services."
        case .unlockFailed:
            return "Failed to unlock system preferences."
        case let .retryExhausted(lastErrorMessage):
            return "Retry attempts exhausted. Last error: \(lastErrorMessage)"
        case let .invalidConfiguration(message):
            return "Invalid configuration: \(message)"
        case let .batchOperationFailed(errors):
            let details = errors.map { "\($0.service): \($0.message)" }.joined(separator: "; ")
            return "All batch operations failed: \(details)"
        case let .unknown(message):
            return "Unknown error: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .preferencesCreationFailed:
            return "Ensure the app is properly signed and has the necessary entitlements."
        case .lockFailed:
            return "Wait a moment and try again. Close any other apps that might be modifying network settings."
        case .serviceNotFound:
            return "Use 'networksetup -listallnetworkservices' to list available network services."
        case .protocolNotFound, .configurationNotFound:
            return "This may indicate a corrupted network configuration. Try creating a new network location."
        case .commitFailed:
            return "Run the application with administrator privileges or provide a valid authorization reference."
        case .applyFailed:
            return "Try running 'sudo killall -HUP configd' to restart the configuration daemon."
        case .unlockFailed:
            return nil
        case .retryExhausted:
            return "Consider increasing the retry policy or investigating the underlying issue."
        case .invalidConfiguration:
            return "Review and correct the configuration parameters."
        case .batchOperationFailed:
            return "Check individual service errors for details. Some services may not exist or may be disabled."
        case .unknown:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension SystemProxyError: CustomStringConvertible {
    public var description: String {
        errorDescription ?? "SystemProxyError"
    }
}
