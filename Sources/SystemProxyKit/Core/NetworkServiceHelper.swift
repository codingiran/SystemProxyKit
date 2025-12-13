//
//  NetworkServiceHelper.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation
import SystemConfiguration

/// 网络服务查找辅助工具
/// 负责屏蔽 SCNetworkService 的查找细节
public enum NetworkServiceHelper: Sendable {
    /// 通过服务名称查找网络服务
    /// - Parameters:
    ///   - name: 服务名称，例如 "Wi-Fi" 或 "Ethernet"
    ///   - prefs: SCPreferences 会话
    /// - Returns: 匹配的 SCNetworkService，如果未找到则返回 nil
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

    /// 通过 BSD 名称查找网络服务
    /// - Parameters:
    ///   - bsdName: BSD 设备名称，例如 "en0" 或 "en1"
    ///   - prefs: SCPreferences 会话
    /// - Returns: 匹配的 SCNetworkService，如果未找到则返回 nil
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

    /// 获取所有网络服务名称
    /// - Parameter prefs: SCPreferences 会话
    /// - Returns: 网络服务名称列表
    public static func allServiceNames(in prefs: SCPreferences) -> [String] {
        guard let services = SCNetworkServiceCopyAll(prefs) as? [SCNetworkService] else {
            return []
        }

        return services.compactMap { service in
            SCNetworkServiceGetName(service) as String?
        }
    }

    /// 获取服务的代理协议
    /// - Parameter service: 网络服务
    /// - Returns: 代理协议，如果未找到则返回 nil
    public static func getProxiesProtocol(
        for service: SCNetworkService
    ) -> SCNetworkProtocol? {
        SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies)
    }

    /// 获取服务的代理配置字典
    /// - Parameter service: 网络服务
    /// - Returns: 代理配置字典，如果未找到则返回 nil
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
    /// 网络服务信息
    struct ServiceInfo: Sendable {
        /// 服务名称
        public let name: String

        /// BSD 设备名称
        public let bsdName: String?

        /// 接口类型（如 IEEE80211, Ethernet）
        public let interfaceType: String?

        /// 是否启用
        public let isEnabled: Bool
    }

    /// 获取所有网络服务的详细信息
    /// - Parameter prefs: SCPreferences 会话
    /// - Returns: 网络服务信息列表
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
