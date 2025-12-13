//
//  NetworkServiceHelper.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation
import SystemConfiguration

/// Network service lookup helper
/// Abstracts away SCNetworkService lookup details
public enum NetworkServiceHelper: Sendable {
    /// Finds network service by service name
    /// - Parameters:
    ///   - name: Service name, e.g., "Wi-Fi" or "Ethernet"
    ///   - prefs: SCPreferences session
    /// - Returns: Matching SCNetworkService, or nil if not found
    public static func findService(
        byName name: String,
        in prefs: SCPreferences
    ) -> SCNetworkService? {
        guard let services = SCNetworkServiceCopyAll(prefs) as? [SCNetworkService] else {
            return nil
        }

        for service in services {
            if let serviceName = SCNetworkServiceGetName(service) as String?,
               serviceName == name
            {
                return service
            }
        }

        return nil
    }

    /// Finds network service by BSD name
    /// - Parameters:
    ///   - bsdName: BSD device name, e.g., "en0" or "en1"
    ///   - prefs: SCPreferences session
    /// - Returns: Matching SCNetworkService, or nil if not found
    public static func findService(
        byBSDName bsdName: String,
        in prefs: SCPreferences
    ) -> SCNetworkService? {
        guard let services = SCNetworkServiceCopyAll(prefs) as? [SCNetworkService] else {
            return nil
        }

        for service in services {
            if let interface = SCNetworkServiceGetInterface(service),
               let interfaceBSDName = SCNetworkInterfaceGetBSDName(interface) as String?,
               interfaceBSDName == bsdName
            {
                return service
            }
        }

        return nil
    }

    /// Gets all network service names
    /// - Parameter prefs: SCPreferences session
    /// - Returns: List of network service names
    public static func allServiceNames(in prefs: SCPreferences) -> [String] {
        guard let services = SCNetworkServiceCopyAll(prefs) as? [SCNetworkService] else {
            return []
        }

        return services.compactMap { service in
            SCNetworkServiceGetName(service) as String?
        }
    }

    /// Gets the proxies protocol for a service
    /// - Parameter service: Network service
    /// - Returns: Proxies protocol, or nil if not found
    public static func getProxiesProtocol(
        for service: SCNetworkService
    ) -> SCNetworkProtocol? {
        SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies)
    }

    /// Gets proxy configuration dictionary for a service
    /// - Parameter service: Network service
    /// - Returns: Proxy configuration dictionary, or nil if not found
    public static func getProxyConfiguration(
        for service: SCNetworkService
    ) -> [String: Any]? {
        guard let proxiesProtocol = getProxiesProtocol(for: service) else {
            return nil
        }

        return SCNetworkProtocolGetConfiguration(proxiesProtocol) as? [String: Any]
    }
}

// MARK: - Service Info

public extension NetworkServiceHelper {
    /// Network service information
    struct ServiceInfo: Sendable {
        /// Service name
        public let name: String

        /// BSD device name
        public let bsdName: String?

        /// Interface type (e.g., IEEE80211, Ethernet)
        public let interfaceType: String?

        /// Whether the service is enabled
        public let isEnabled: Bool
    }

    /// Gets detailed information for all network services
    /// - Parameter prefs: SCPreferences session
    /// - Returns: List of network service information
    static func allServices(in prefs: SCPreferences) -> [ServiceInfo] {
        guard let services = SCNetworkServiceCopyAll(prefs) as? [SCNetworkService] else {
            return []
        }

        return services.compactMap { service -> ServiceInfo? in
            guard let name = SCNetworkServiceGetName(service) as String? else {
                return nil
            }

            let interface = SCNetworkServiceGetInterface(service)
            let bsdName = interface.flatMap { SCNetworkInterfaceGetBSDName($0) as String? }
            let interfaceType = interface.flatMap { SCNetworkInterfaceGetInterfaceType($0) as String? }
            let isEnabled = SCNetworkServiceGetEnabled(service)

            return ServiceInfo(
                name: name,
                bsdName: bsdName,
                interfaceType: interfaceType,
                isEnabled: isEnabled
            )
        }
    }
}
