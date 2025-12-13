//
//  PrivilegedIntegrationTests.swift
//  SystemProxyKitTests
//
//  Integration tests that require root/admin privileges.
//
//  ⚠️ WARNING: These tests MODIFY REAL SYSTEM PROXY SETTINGS!
//
//  To run these tests, use:
//      sudo swift test --filter Privileged
//
//  Each test is designed to:
//  1. Backup current configuration
//  2. Make changes
//  3. Verify changes
//  4. Restore original configuration
//

import Foundation
@testable import SystemProxyKit
import Testing

// MARK: - Privileged Proxy Write Tests

@Suite("Privileged Proxy Write Tests", .tags(.privileged), .serialized)
struct PrivilegedProxyWriteTests {
    /// Checks if the process has root privileges
    /// If not, skips the test
    private func skipIfNotRoot() -> Bool {
        if getuid() != 0 {
            print("⏭️ Skipping: Test requires root privileges. Run with: sudo swift test --filter Privileged")
            return true
        }
        return false
    }

    /// Gets the first available network service name
    private func getTestServiceName() async throws -> String {
        let services = try await SystemProxyKit.availableServices()
        // Prefer Wi-Fi, otherwise use the first available service
        if services.contains("Wi-Fi") {
            return "Wi-Fi"
        }
        guard let first = services.first else {
            throw SystemProxyError.unknown(message: "No network service available for testing")
        }
        return first
    }

    @Test("Set and restore HTTP proxy")
    func setHTTPProxy() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // 1. Backup current configuration
        let originalConfig = try await SystemProxyKit.current(for: serviceName)
        print("Original config: \(originalConfig)")

        // 2. Set test proxy
        var testConfig = originalConfig
        testConfig.httpProxy = ProxyServer(
            host: "127.0.0.1",
            port: 18080,
            isEnabled: true
        )
        testConfig.httpsProxy = ProxyServer(
            host: "127.0.0.1",
            port: 18080,
            isEnabled: true
        )

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)
        print("Set test proxy configuration")

        // 3. Verify changes took effect
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.httpProxy?.host == "127.0.0.1")
        #expect(verifyConfig.httpProxy?.port == 18080)
        #expect(verifyConfig.httpProxy?.isEnabled == true)
        #expect(verifyConfig.httpsProxy?.host == "127.0.0.1")
        #expect(verifyConfig.httpsProxy?.port == 18080)

        print("✅ Verified proxy was set correctly")

        // 4. Restore original configuration (MUST be synchronous!)
        try await SystemProxyKit.setProxy(originalConfig, for: serviceName)
        print("✅ Restored original configuration")
    }

    @Test("Set and restore SOCKS proxy")
    func setSOCKSProxy() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // Backup
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        // Set SOCKS proxy
        var testConfig = originalConfig
        testConfig.socksProxy = ProxyServer(
            host: "127.0.0.1",
            port: 11080,
            isEnabled: true
        )

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)

        // Verify
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.socksProxy?.host == "127.0.0.1")
        #expect(verifyConfig.socksProxy?.port == 11080)
        #expect(verifyConfig.socksProxy?.isEnabled == true)

        // Restore
        try await SystemProxyKit.setProxy(originalConfig, for: serviceName)
        print("✅ Restored original configuration")
    }

    @Test("Set and restore PAC configuration")
    func setPACProxy() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // Backup
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        // Set PAC
        var testConfig = originalConfig
        testConfig.autoConfigURL = PACConfiguration(
            url: URL(string: "http://example.com/proxy.pac")!,
            isEnabled: true
        )

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)

        // Verify
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.autoConfigURL?.url.absoluteString == "http://example.com/proxy.pac")
        #expect(verifyConfig.autoConfigURL?.isEnabled == true)

        // Restore
        try await SystemProxyKit.setProxy(originalConfig, for: serviceName)
        print("✅ Restored original configuration")
    }

    @Test("Disable all proxies")
    func disableAllProxies() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // Backup
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        // First set some proxies
        var testConfig = originalConfig
        testConfig.httpProxy = ProxyServer(host: "127.0.0.1", port: 8080, isEnabled: true)
        testConfig.autoDiscoveryEnabled = true

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)

        // Then disable all proxies
        try await SystemProxyKit.disableAllProxies(for: serviceName)

        // Verify
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(!verifyConfig.hasAnyProxyEnabled)
        #expect(!verifyConfig.autoDiscoveryEnabled)
        #expect(verifyConfig.httpProxy?.isEnabled != true)

        // Restore
        try await SystemProxyKit.setProxy(originalConfig, for: serviceName)
        print("✅ Restored original configuration")
    }

    @Test("Set exception list")
    func setExceptionList() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // Backup
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        // Set exception list
        var testConfig = originalConfig
        testConfig.excludeSimpleHostnames = true
        testConfig.exceptionList = ["*.local", "169.254/16"]

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)

        // Verify
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.excludeSimpleHostnames == true)
        #expect(verifyConfig.exceptionList.contains("*.local"))
        #expect(verifyConfig.exceptionList.contains("169.254/16"))

        // Restore
        try await SystemProxyKit.setProxy(originalConfig, for: serviceName)
        print("✅ Restored original configuration")
    }

    @Test("Convenience method setHTTPProxy works")
    func convenienceSetHTTPProxy() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // Backup
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        // Use convenience method
        try await SystemProxyKit.setHTTPProxy(host: "127.0.0.1", port: 19999, for: serviceName)

        // Verify
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.httpProxy?.host == "127.0.0.1")
        #expect(verifyConfig.httpProxy?.port == 19999)
        #expect(verifyConfig.httpsProxy?.host == "127.0.0.1")
        #expect(verifyConfig.httpsProxy?.port == 19999)

        // Restore
        try await SystemProxyKit.setProxy(originalConfig, for: serviceName)
        print("✅ Restored original configuration")
    }
}

// MARK: - Test Tags

extension Tag {
    /// Tests that require root/admin privileges
    @Tag static var privileged: Self
}
