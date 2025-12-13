//
//  SystemProxyManager.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation
import Security
import SystemConfiguration

/// 系统代理管理器
/// 负责事务管理、权限上下文持有、API 暴露
/// 使用 actor 确保线程安全
public actor SystemProxyManager {
    // MARK: - Properties

    /// 应用程序标识符，用于创建 SCPreferences
    private let appIdentifier: String

    /// 授权引用（可选）
    private var authRef: AuthorizationRef?

    // MARK: - Initialization

    /// 初始化系统代理管理器
    /// - Parameters:
    ///   - appIdentifier: 应用程序标识符，用于 SCPreferences
    ///   - authRef: 授权引用（可选，用于特权操作）
    public init(
        appIdentifier: String = Bundle.main.bundleIdentifier ?? "SystemProxyKit",
        authRef: AuthorizationRef? = nil
    ) {
        self.appIdentifier = appIdentifier
        self.authRef = authRef
    }

    // MARK: - Public API

    /// 获取指定网络接口的当前代理配置
    /// - Parameter interface: 网络接口名称，例如 "Wi-Fi"
    /// - Returns: 当前的代理配置
    /// - Throws: SystemProxyError
    public func getConfiguration(for interface: String) async throws -> ProxyConfiguration {
        // 创建只读 SCPreferences 会话
        guard let prefs = SCPreferencesCreate(nil, appIdentifier as CFString, nil) else {
            throw SystemProxyError.preferencesCreationFailed
        }

        // 查找网络服务
        guard let service = NetworkServiceHelper.findService(byName: interface, in: prefs) else {
            throw SystemProxyError.serviceNotFound(name: interface)
        }

        // 获取代理配置字典
        guard let configDict = NetworkServiceHelper.getProxyConfiguration(for: service) else {
            throw SystemProxyError.configurationNotFound(serviceName: interface)
        }

        // 转换为 ProxyConfiguration 模型
        return ProxyConfiguration(fromSCDictionary: configDict)
    }

    /// 设置指定网络接口的代理配置
    /// - Parameters:
    ///   - interface: 网络接口名称
    ///   - configuration: 新的代理配置
    ///   - authRef: 授权引用（可选，覆盖实例级别的授权）
    ///   - retryPolicy: 重试策略
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

    /// 获取所有可用的网络服务名称
    /// - Returns: 网络服务名称列表
    public func availableServices() async throws -> [String] {
        guard let prefs = SCPreferencesCreate(nil, appIdentifier as CFString, nil) else {
            throw SystemProxyError.preferencesCreationFailed
        }

        return NetworkServiceHelper.allServiceNames(in: prefs)
    }

    /// 获取所有网络服务的详细信息
    /// - Returns: 网络服务信息列表
    public func allServicesInfo() async throws -> [NetworkServiceHelper.ServiceInfo] {
        guard let prefs = SCPreferencesCreate(nil, appIdentifier as CFString, nil) else {
            throw SystemProxyError.preferencesCreationFailed
        }

        return NetworkServiceHelper.allServices(in: prefs)
    }

    /// 设置授权引用
    /// - Parameter authRef: 新的授权引用
    public func setAuthorizationRef(_ authRef: AuthorizationRef?) {
        self.authRef = authRef
    }

    // MARK: - Private Implementation

    /// 执行设置代理的核心逻辑
    private func performSetProxy(
        for interface: String,
        configuration: ProxyConfiguration,
        authRef: AuthorizationRef?
    ) async throws {
        // 创建带授权的 SCPreferences 会话
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

        // 锁定 SCPreferences
        guard SCPreferencesLock(prefs, true) else {
            throw SystemProxyError.lockFailed
        }

        // 确保解锁
        defer {
            SCPreferencesUnlock(prefs)
        }

        // 查找网络服务
        guard let service = NetworkServiceHelper.findService(byName: interface, in: prefs) else {
            throw SystemProxyError.serviceNotFound(name: interface)
        }

        // 获取代理协议
        guard let proxiesProtocol = NetworkServiceHelper.getProxiesProtocol(for: service) else {
            throw SystemProxyError.protocolNotFound(serviceName: interface)
        }

        // 获取现有配置并合并新配置
        let existingConfig = SCNetworkProtocolGetConfiguration(proxiesProtocol) as? [String: Any] ?? [:]
        let newConfigDict = configuration.mergeIntoSCDictionary(existingConfig)

        // 设置新配置
        guard SCNetworkProtocolSetConfiguration(proxiesProtocol, newConfigDict as CFDictionary) else {
            throw SystemProxyError.commitFailed
        }

        // 提交更改
        guard SCPreferencesCommitChanges(prefs) else {
            throw SystemProxyError.commitFailed
        }

        // 应用更改
        guard SCPreferencesApplyChanges(prefs) else {
            throw SystemProxyError.applyFailed
        }
    }

    /// 带重试的执行
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

                // 只对 lockFailed 错误进行重试
                guard case .lockFailed = error, attempt < policy.maxRetries else {
                    throw error
                }

                // 计算延迟时间
                let delay = policy.delayForAttempt(attempt + 1)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw SystemProxyError.retryExhausted(lastErrorMessage: lastError?.localizedDescription ?? "Unknown error during retry")
    }
}

// MARK: - Convenience Extensions

public extension SystemProxyManager {
    /// 快速禁用所有代理
    /// - Parameter interface: 网络接口名称
    func disableAllProxies(for interface: String) async throws {
        var config = try await getConfiguration(for: interface)
        config.disableAllProxies()
        try await setProxy(for: interface, configuration: config)
    }

    /// 快速设置 HTTP/HTTPS 代理
    /// - Parameters:
    ///   - host: 代理主机
    ///   - port: 代理端口
    ///   - interface: 网络接口名称
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

    /// 快速设置 SOCKS 代理
    /// - Parameters:
    ///   - host: 代理主机
    ///   - port: 代理端口
    ///   - interface: 网络接口名称
    func setSOCKSProxy(
        host: String,
        port: Int,
        for interface: String
    ) async throws {
        var config = try await getConfiguration(for: interface)
        config.socksProxy = ProxyServer(host: host, port: port, isEnabled: true)
        try await setProxy(for: interface, configuration: config)
    }

    /// 快速设置 PAC 自动代理
    /// - Parameters:
    ///   - url: PAC 脚本 URL
    ///   - interface: 网络接口名称
    func setPACProxy(
        url: URL,
        for interface: String
    ) async throws {
        var config = try await getConfiguration(for: interface)
        config.autoConfigURL = PACConfiguration(url: url, isEnabled: true)
        try await setProxy(for: interface, configuration: config)
    }
}
