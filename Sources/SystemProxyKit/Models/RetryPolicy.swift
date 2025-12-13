//
//  RetryPolicy.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// 描述操作失败时的重试策略
public struct RetryPolicy: Equatable, Sendable {
    /// 最大重试次数
    public let maxRetries: Int

    /// 重试间隔（秒）
    public let delay: TimeInterval

    /// 退避倍数（指数退避）
    public let backoffMultiplier: Double

    /// 初始化重试策略
    /// - Parameters:
    ///   - maxRetries: 最大重试次数
    ///   - delay: 重试间隔（秒）
    ///   - backoffMultiplier: 退避倍数
    public init(maxRetries: Int, delay: TimeInterval, backoffMultiplier: Double) {
        self.maxRetries = maxRetries
        self.delay = delay
        self.backoffMultiplier = backoffMultiplier
    }

    /// 计算第 n 次重试的延迟时间
    /// - Parameter attempt: 重试次数（从 0 开始）
    /// - Returns: 延迟时间（秒）
    public func delayForAttempt(_ attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        return delay * pow(backoffMultiplier, Double(attempt - 1))
    }
}

// MARK: - Preset Policies

public extension RetryPolicy {
    /// 不重试
    static let none = RetryPolicy(maxRetries: 0, delay: 0, backoffMultiplier: 1.0)

    /// 默认策略：3 次重试，0.5 秒起始延迟，2 倍指数退避
    static let `default` = RetryPolicy(maxRetries: 3, delay: 0.5, backoffMultiplier: 2.0)

    /// 激进策略：5 次重试，0.2 秒起始延迟，1.5 倍指数退避
    static let aggressive = RetryPolicy(maxRetries: 5, delay: 0.2, backoffMultiplier: 1.5)
}

// MARK: - CustomStringConvertible

extension RetryPolicy: CustomStringConvertible {
    public var description: String {
        "RetryPolicy(maxRetries: \(maxRetries), delay: \(delay)s, backoff: \(backoffMultiplier)x)"
    }
}
