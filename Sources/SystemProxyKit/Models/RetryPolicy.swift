//
//  RetryPolicy.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// Retry strategy for failed operations
public struct RetryPolicy: Equatable, Sendable {
    /// Maximum number of retry attempts
    public let maxRetries: Int

    /// Retry interval in seconds
    public let delay: TimeInterval

    /// Backoff multiplier (for exponential backoff)
    public let backoffMultiplier: Double

    /// Initializes retry policy
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts
    ///   - delay: Retry interval in seconds
    ///   - backoffMultiplier: Backoff multiplier
    public init(maxRetries: Int, delay: TimeInterval, backoffMultiplier: Double) {
        self.maxRetries = maxRetries
        self.delay = delay
        self.backoffMultiplier = backoffMultiplier
    }

    /// Calculates delay for the nth retry attempt
    /// - Parameter attempt: Retry attempt number (starting from 0)
    /// - Returns: Delay time in seconds
    public func delayForAttempt(_ attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        return delay * pow(backoffMultiplier, Double(attempt - 1))
    }
}

// MARK: - Preset Policies

public extension RetryPolicy {
    /// No retry
    static let none = RetryPolicy(maxRetries: 0, delay: 0, backoffMultiplier: 1.0)

    /// Default policy: 3 retries, 0.5s initial delay, 2x exponential backoff
    static let `default` = RetryPolicy(maxRetries: 3, delay: 0.5, backoffMultiplier: 2.0)

    /// Aggressive policy: 5 retries, 0.2s initial delay, 1.5x exponential backoff
    static let aggressive = RetryPolicy(maxRetries: 5, delay: 0.2, backoffMultiplier: 1.5)
}

// MARK: - CustomStringConvertible

extension RetryPolicy: CustomStringConvertible {
    public var description: String {
        "RetryPolicy(maxRetries: \(maxRetries), delay: \(delay)s, backoff: \(backoffMultiplier)x)"
    }
}
