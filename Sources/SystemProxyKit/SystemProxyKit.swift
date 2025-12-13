//
//  SystemProxyKit.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation
import Security

/// SystemProxyKit 库的统一入口
/// 提供便捷的静态方法访问常用功能
public enum SystemProxyKit {
    // MARK: - Shared Manager

    /// 共享的代理管理器实例
    public static let shared = SystemProxyManager()

    // MARK: - Quick Access API

    /// 快速获取指定网络接口的当前代理配置
    /// - Parameter interface: 网络接口名称，例如 "Wi-Fi"
    /// - Returns: 当前的代理配置
    /// - Throws: SystemProxyError
    public static func current(for interface: String) async throws -> ProxyConfiguration {
        try await shared.getConfiguration(for: interface)
    }

    /// 快速设置指定网络接口的代理配置
    /// - Parameters:
    ///   - config: 新的代理配置
    ///   - interface: 网络接口名称
    ///   - retryPolicy: 重试策略，默认为 .default
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

    /// 获取所有可用的网络服务名称
    /// - Returns: 网络服务名称列表
    public static func availableServices() async throws -> [String] {
        try await shared.availableServices()
    }

    /// 获取所有网络服务的详细信息
    /// - Returns: 网络服务信息列表
    public static func allServicesInfo() async throws -> [NetworkServiceHelper.ServiceInfo] {
        try await shared.allServicesInfo()
    }

    // MARK: - Convenience Methods

    /// 快速禁用所有代理
    /// - Parameter interface: 网络接口名称
    public static func disableAllProxies(for interface: String) async throws {
        try await shared.disableAllProxies(for: interface)
    }

    /// 快速设置 HTTP/HTTPS 代理
    /// - Parameters:
    ///   - host: 代理主机
    ///   - port: 代理端口
    ///   - interface: 网络接口名称
    public static func setHTTPProxy(
        host: String,
        port: Int,
        for interface: String
    ) async throws {
        try await shared.setHTTPProxy(host: host, port: port, for: interface)
    }

    /// 快速设置 SOCKS 代理
    /// - Parameters:
    ///   - host: 代理主机
    ///   - port: 代理端口
    ///   - interface: 网络接口名称
    public static func setSOCKSProxy(
        host: String,
        port: Int,
        for interface: String
    ) async throws {
        try await shared.setSOCKSProxy(host: host, port: port, for: interface)
    }

    /// 快速设置 PAC 自动代理
    /// - Parameters:
    ///   - url: PAC 脚本 URL
    ///   - interface: 网络接口名称
    public static func setPACProxy(
        url: URL,
        for interface: String
    ) async throws {
        try await shared.setPACProxy(url: url, for: interface)
    }
}

// MARK: - Re-exports

// 导出所有公开类型，方便使用者只需 import SystemProxyKit
public typealias ProxyError = SystemProxyError
