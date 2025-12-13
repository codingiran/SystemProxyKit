//
//  SystemProxyError.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// SystemProxyKit 错误枚举
public enum SystemProxyError: Error, Sendable {
    /// 创建 SCPreferences 失败（系统资源不足或权限严重拒绝）
    case preferencesCreationFailed

    /// 锁定 SCPreferences 失败（其他进程正在修改网络设置）
    case lockFailed

    /// 找不到指定的网络服务
    case serviceNotFound(name: String)

    /// 找不到指定服务的代理协议
    case protocolNotFound(serviceName: String)

    /// 获取代理配置失败
    case configurationNotFound(serviceName: String)

    /// 写入系统数据库失败
    case commitFailed

    /// 配置写入成功但无法生效
    case applyFailed

    /// 解锁 SCPreferences 失败
    case unlockFailed

    /// 重试次数耗尽
    case retryExhausted(lastErrorMessage: String)

    /// 无效的配置参数
    case invalidConfiguration(message: String)

    /// 未知错误
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
