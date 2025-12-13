//
//  ProxyServer.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// 描述单个代理服务器节点，支持可选的认证信息
public struct ProxyServer: Equatable, Hashable, Sendable, Codable {
    /// 主机名或 IP 地址
    public let host: String

    /// 端口号
    public let port: Int

    /// 开关状态
    public var isEnabled: Bool

    /// 认证用户名（可选）
    public let username: String?

    /// 认证密码（可选，建议使用 Keychain 安全存储）
    public let password: String?

    /// 初始化代理服务器配置
    /// - Parameters:
    ///   - host: 主机名或 IP 地址
    ///   - port: 端口号
    ///   - isEnabled: 开关状态，默认为 true
    ///   - username: 认证用户名（可选）
    ///   - password: 认证密码（可选）
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

    /// 是否配置了认证信息
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
