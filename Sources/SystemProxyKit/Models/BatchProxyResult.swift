//
//  BatchProxyResult.swift
//  SystemProxyKit
//
//  Created by SystemProxyKit
//

import Foundation

/// Result of a batch proxy configuration operation
public struct BatchProxyResult: Sendable {
    /// Network services that were successfully configured
    public let succeeded: [String]

    /// Network services that failed with their respective errors
    public let failed: [(service: String, error: Error)]

    /// Whether all operations succeeded
    public var allSucceeded: Bool {
        failed.isEmpty
    }

    /// Whether all operations failed
    public var allFailed: Bool {
        succeeded.isEmpty
    }

    /// Total number of operations attempted
    public var totalCount: Int {
        succeeded.count + failed.count
    }

    /// Number of successful operations
    public var successCount: Int {
        succeeded.count
    }

    /// Number of failed operations
    public var failureCount: Int {
        failed.count
    }

    /// Creates a batch proxy result
    /// - Parameters:
    ///   - succeeded: List of successfully configured services
    ///   - failed: List of failed services with their errors
    public init(succeeded: [String], failed: [(service: String, error: Error)]) {
        self.succeeded = succeeded
        self.failed = failed
    }
}

// MARK: - CustomStringConvertible

extension BatchProxyResult: CustomStringConvertible {
    public var description: String {
        if allSucceeded {
            return "BatchProxyResult(all \(successCount) succeeded)"
        } else if allFailed {
            return "BatchProxyResult(all \(failureCount) failed)"
        } else {
            return "BatchProxyResult(\(successCount) succeeded, \(failureCount) failed)"
        }
    }
}
