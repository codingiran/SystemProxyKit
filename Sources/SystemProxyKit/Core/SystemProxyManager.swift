//
//  SystemProxyManager.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation
import Security
import SystemConfiguration

/// System proxy manager
/// Responsible for transaction management, authorization context holding, and API exposure
/// Uses actor to ensure thread safety
public actor SystemProxyManager {
    // MARK: - Properties

    /// Application identifier used for creating SCPreferences
    private let appIdentifier: String

    /// Authorization reference (optional)
    private var authRef: AuthorizationRef?

    // MARK: - Initialization

    /// Initializes system proxy manager
    /// - Parameters:
    ///   - appIdentifier: Application identifier for SCPreferences
    ///   - authRef: Authorization reference (optional, for privileged operations)
    public init(
        appIdentifier: String = Bundle.main.bundleIdentifier ?? "SystemProxyKit",
        authRef: AuthorizationRef? = nil
    ) {
        self.appIdentifier = appIdentifier
        self.authRef = authRef
    }

    // MARK: - Public API

    /// Gets current proxy configuration for specified network interface
    /// - Parameter interface: Network interface name, e.g., "Wi-Fi"
    /// - Returns: Current proxy configuration
    /// - Throws: SystemProxyError
    public func getConfiguration(for interface: String) async throws -> ProxyConfiguration {
        // Create read-only SCPreferences session
        guard let prefs = SCPreferencesCreate(nil, appIdentifier as CFString, nil) else {
            throw SystemProxyError.preferencesCreationFailed
        }

        // Find network service
        guard let service = NetworkServiceHelper.findService(byName: interface, in: prefs) else {
            throw SystemProxyError.serviceNotFound(name: interface)
        }

        // Get proxy configuration dictionary
        guard let configDict = NetworkServiceHelper.getProxyConfiguration(for: service) else {
            throw SystemProxyError.configurationNotFound(serviceName: interface)
        }

        // Convert to ProxyConfiguration model
        return ProxyConfiguration(fromSCDictionary: configDict)
    }

    /// Sets proxy configuration for specified network interface
    /// - Parameters:
    ///   - interface: Network interface name
    ///   - configuration: New proxy configuration
    ///   - authRef: Authorization reference (optional, overrides instance-level auth)
    ///   - retryPolicy: Retry policy
    /// - Throws: SystemProxyError
    public func setProxy(
        for interface: String,
        configuration: ProxyConfiguration,
        authRef: AuthorizationRef? = nil,
        retryPolicy: RetryPolicy = .default
    ) async throws {
        let effectiveAuthRef = authRef ?? self.authRef

        try await withRetry(policy: retryPolicy) {
            try await self.performSetProxy(
                for: interface,
                configuration: configuration,
                authRef: effectiveAuthRef
            )
        }
    }

    /// Gets all available network service names
    /// - Returns: List of network service names
    public func availableServices() async throws -> [String] {
        guard let prefs = SCPreferencesCreate(nil, appIdentifier as CFString, nil) else {
            throw SystemProxyError.preferencesCreationFailed
        }

        return NetworkServiceHelper.allServiceNames(in: prefs)
    }

    /// Gets detailed information for all network services
    /// - Returns: List of network service information
    public func allServicesInfo() async throws -> [NetworkServiceHelper.ServiceInfo] {
        guard let prefs = SCPreferencesCreate(nil, appIdentifier as CFString, nil) else {
            throw SystemProxyError.preferencesCreationFailed
        }

        return NetworkServiceHelper.allServices(in: prefs)
    }

    /// Sets authorization reference
    /// - Parameter authRef: New authorization reference
    public func setAuthorizationRef(_ authRef: AuthorizationRef?) {
        self.authRef = authRef
    }

    // MARK: - Private Implementation

    /// Executes core logic for setting proxy
    private func performSetProxy(
        for interface: String,
        configuration: ProxyConfiguration,
        authRef: AuthorizationRef?
    ) async throws {
        // Create authorized SCPreferences session
        let prefs: SCPreferences
        if let authRef = authRef {
            guard let p = SCPreferencesCreateWithAuthorization(
                nil,
                appIdentifier as CFString,
                nil,
                authRef
            ) else {
                throw SystemProxyError.preferencesCreationFailed
            }
            prefs = p
        } else {
            guard let p = SCPreferencesCreate(nil, appIdentifier as CFString, nil) else {
                throw SystemProxyError.preferencesCreationFailed
            }
            prefs = p
        }

        // Lock SCPreferences
        guard SCPreferencesLock(prefs, true) else {
            throw SystemProxyError.lockFailed
        }

        // Ensure unlock
        defer {
            SCPreferencesUnlock(prefs)
        }

        // Find network service
        guard let service = NetworkServiceHelper.findService(byName: interface, in: prefs) else {
            throw SystemProxyError.serviceNotFound(name: interface)
        }

        // Get proxies protocol
        guard let proxiesProtocol = NetworkServiceHelper.getProxiesProtocol(for: service) else {
            throw SystemProxyError.protocolNotFound(serviceName: interface)
        }

        // Get existing configuration and merge with new configuration
        let existingConfig = SCNetworkProtocolGetConfiguration(proxiesProtocol) as? [String: Any] ?? [:]
        let newConfigDict = configuration.mergeIntoSCDictionary(existingConfig)

        // Set new configuration
        guard SCNetworkProtocolSetConfiguration(proxiesProtocol, newConfigDict as CFDictionary) else {
            throw SystemProxyError.commitFailed
        }

        // Commit changes
        guard SCPreferencesCommitChanges(prefs) else {
            throw SystemProxyError.commitFailed
        }

        // Apply changes
        guard SCPreferencesApplyChanges(prefs) else {
            throw SystemProxyError.applyFailed
        }
    }

    /// Executes with retry
    private func withRetry<T>(
        policy: RetryPolicy,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: SystemProxyError?

        for attempt in 0 ... policy.maxRetries {
            do {
                return try await operation()
            } catch let error as SystemProxyError {
                lastError = error

                // Only retry on lockFailed error
                guard case .lockFailed = error, attempt < policy.maxRetries else {
                    throw error
                }

                // Calculate delay time
                let delay = policy.delayForAttempt(attempt + 1)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw SystemProxyError.retryExhausted(lastErrorMessage: lastError?.localizedDescription ?? "Unknown error during retry")
    }
}

// MARK: - Convenience Extensions

public extension SystemProxyManager {
    /// Quickly disable all proxies
    /// - Parameter interface: Network interface name
    func disableAllProxies(for interface: String) async throws {
        var config = try await getConfiguration(for: interface)
        config.disableAllProxies()
        try await setProxy(for: interface, configuration: config)
    }

    /// Quickly set HTTP/HTTPS proxy
    /// - Parameters:
    ///   - host: Proxy host
    ///   - port: Proxy port
    ///   - interface: Network interface name
    func setHTTPProxy(
        host: String,
        port: Int,
        for interface: String
    ) async throws {
        var config = try await getConfiguration(for: interface)
        let proxy = ProxyServer(host: host, port: port, isEnabled: true)
        config.httpProxy = proxy
        config.httpsProxy = proxy
        try await setProxy(for: interface, configuration: config)
    }

    /// Quickly set SOCKS proxy
    /// - Parameters:
    ///   - host: Proxy host
    ///   - port: Proxy port
    ///   - interface: Network interface name
    func setSOCKSProxy(
        host: String,
        port: Int,
        for interface: String
    ) async throws {
        var config = try await getConfiguration(for: interface)
        config.socksProxy = ProxyServer(host: host, port: port, isEnabled: true)
        try await setProxy(for: interface, configuration: config)
    }

    /// Quickly set PAC automatic proxy
    /// - Parameters:
    ///   - url: PAC script URL
    ///   - interface: Network interface name
    func setPACProxy(
        url: URL,
        for interface: String
    ) async throws {
        var config = try await getConfiguration(for: interface)
        config.autoConfigURL = PACConfiguration(url: url, isEnabled: true)
        try await setProxy(for: interface, configuration: config)
    }
}
