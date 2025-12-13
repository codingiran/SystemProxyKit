//
//  SystemProxyKit.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.10)
    #error("SystemProxyKit doesn't support Swift versions below 5.10.")
#endif

/// Current SystemProxyKit version Release 0.0.1. Necessary since SPM doesn't use dynamic libraries. Plus this will be more accurate.
public let version = "0.0.1"

/// Unified entry point for SystemProxyKit library
/// Provides convenient static methods for accessing common functionality
public enum SystemProxyKit {
    // MARK: - Shared Manager

    /// Shared proxy manager instance
    public static let shared = SystemProxyManager()

    // MARK: - Quick Access API

    /// Quickly gets current proxy configuration for specified network interface
    /// - Parameter interface: Network interface name, e.g., "Wi-Fi"
    /// - Returns: Current proxy configuration
    /// - Throws: SystemProxyError
    public static func current(for interface: String) async throws -> ProxyConfiguration {
        try await shared.getConfiguration(for: interface)
    }

    /// Quickly sets proxy configuration for specified network interface
    /// - Parameters:
    ///   - config: New proxy configuration
    ///   - interface: Network interface name
    ///   - retryPolicy: Retry policy, defaults to .default
    /// - Throws: SystemProxyError
    public static func setProxy(
        _ config: ProxyConfiguration,
        for interface: String,
        retryPolicy: RetryPolicy = .default
    ) async throws {
        try await shared.setProxy(
            for: interface,
            configuration: config,
            retryPolicy: retryPolicy
        )
    }

    /// Gets all available network service names
    /// - Returns: List of network service names
    public static func availableServices() async throws -> [String] {
        try await shared.availableServices()
    }

    /// Gets detailed information for all network services
    /// - Returns: List of network service information
    public static func allServicesInfo() async throws -> [NetworkServiceHelper.ServiceInfo] {
        try await shared.allServicesInfo()
    }

    // MARK: - Convenience Methods

    /// Quickly disable all proxies
    /// - Parameter interface: Network interface name
    public static func disableAllProxies(for interface: String) async throws {
        try await shared.disableAllProxies(for: interface)
    }

    /// Quickly set HTTP/HTTPS proxy
    /// - Parameters:
    ///   - host: Proxy host
    ///   - port: Proxy port
    ///   - interface: Network interface name
    public static func setHTTPProxy(
        host: String,
        port: Int,
        for interface: String
    ) async throws {
        try await shared.setHTTPProxy(host: host, port: port, for: interface)
    }

    /// Quickly set SOCKS proxy
    /// - Parameters:
    ///   - host: Proxy host
    ///   - port: Proxy port
    ///   - interface: Network interface name
    public static func setSOCKSProxy(
        host: String,
        port: Int,
        for interface: String
    ) async throws {
        try await shared.setSOCKSProxy(host: host, port: port, for: interface)
    }

    /// Quickly set PAC automatic proxy
    /// - Parameters:
    ///   - url: PAC script URL
    ///   - interface: Network interface name
    public static func setPACProxy(
        url: URL,
        for interface: String
    ) async throws {
        try await shared.setPACProxy(url: url, for: interface)
    }
}

// MARK: - Re-exports

// Export all public types for convenience when importing SystemProxyKit
public typealias ProxyError = SystemProxyError
