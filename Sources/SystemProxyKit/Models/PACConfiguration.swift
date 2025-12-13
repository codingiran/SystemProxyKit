//
//  PACConfiguration.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// 描述 PAC (Proxy Auto-Configuration) 自动代理配置
public struct PACConfiguration: Equatable, Hashable, Sendable, Codable {
    /// PAC 脚本的 URL 地址
    public let url: URL

    /// 开关状态
    public var isEnabled: Bool

    /// 初始化 PAC 配置
    /// - Parameters:
    ///   - url: PAC 脚本的 URL 地址
    ///   - isEnabled: 开关状态，默认为 true
    public init(url: URL, isEnabled: Bool = true) {
        self.url = url
        self.isEnabled = isEnabled
    }

    /// 从 URL 字符串初始化
    /// - Parameters:
    ///   - urlString: PAC 脚本的 URL 字符串
    ///   - isEnabled: 开关状态，默认为 true
    /// - Returns: 如果 URL 无效则返回 nil
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
