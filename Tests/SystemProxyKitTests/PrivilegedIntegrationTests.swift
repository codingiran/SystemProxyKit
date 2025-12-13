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
    /// 检查是否具有 root 权限
    /// 如果没有权限，跳过测试
    private func skipIfNotRoot() -> Bool {
        if getuid() != 0 {
            print("⏭️ Skipping: Test requires root privileges. Run with: sudo swift test --filter Privileged")
            return true
        }
        return false
    }

    /// 获取第一个可用的网络服务名称
    private func getTestServiceName() async throws -> String {
        let services = try await SystemProxyKit.availableServices()
        // 优先使用 Wi-Fi，否则使用第一个可用的服务
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

        // 1. 备份当前配置
        let originalConfig = try await SystemProxyKit.current(for: serviceName)
        print("Original config: \(originalConfig)")

        defer {
            // 4. 恢复原始配置（无论测试成功与否）
            Task {
                do {
                    try await SystemProxyKit.setProxy(originalConfig, for: serviceName)
                    print("✅ Restored original configuration")
                } catch {
                    print("❌ Failed to restore configuration: \(error)")
                }
            }
        }

        // 2. 设置测试代理
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

        // 3. 验证更改生效
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.httpProxy?.host == "127.0.0.1")
        #expect(verifyConfig.httpProxy?.port == 18080)
        #expect(verifyConfig.httpProxy?.isEnabled == true)
        #expect(verifyConfig.httpsProxy?.host == "127.0.0.1")
        #expect(verifyConfig.httpsProxy?.port == 18080)

        print("✅ Verified proxy was set correctly")
    }

    @Test("Set and restore SOCKS proxy")
    func setSOCKSProxy() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // 备份
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        defer {
            Task {
                try? await SystemProxyKit.setProxy(originalConfig, for: serviceName)
            }
        }

        // 设置 SOCKS 代理
        var testConfig = originalConfig
        testConfig.socksProxy = ProxyServer(
            host: "127.0.0.1",
            port: 11080,
            isEnabled: true
        )

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)

        // 验证
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.socksProxy?.host == "127.0.0.1")
        #expect(verifyConfig.socksProxy?.port == 11080)
        #expect(verifyConfig.socksProxy?.isEnabled == true)
    }

    @Test("Set and restore PAC configuration")
    func setPACProxy() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // 备份
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        defer {
            Task {
                try? await SystemProxyKit.setProxy(originalConfig, for: serviceName)
            }
        }

        // 设置 PAC
        var testConfig = originalConfig
        testConfig.autoConfigURL = PACConfiguration(
            url: URL(string: "http://127.0.0.1:8080/proxy.pac")!,
            isEnabled: true
        )

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)

        // 验证
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.autoConfigURL?.isEnabled == true)
        #expect(verifyConfig.autoConfigURL?.url.absoluteString == "http://127.0.0.1:8080/proxy.pac")
    }

    @Test("Disable all proxies")
    func disableAllProxies() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // 备份
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        defer {
            Task {
                try? await SystemProxyKit.setProxy(originalConfig, for: serviceName)
            }
        }

        // 先设置一些代理
        var testConfig = originalConfig
        testConfig.httpProxy = ProxyServer(host: "127.0.0.1", port: 8080, isEnabled: true)
        testConfig.autoDiscoveryEnabled = true

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)

        // 然后禁用所有代理
        try await SystemProxyKit.disableAllProxies(for: serviceName)

        // 验证
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(!verifyConfig.hasAnyProxyEnabled)
        #expect(!verifyConfig.autoDiscoveryEnabled)
        #expect(verifyConfig.httpProxy?.isEnabled != true)
    }

    @Test("Set exception list")
    func setExceptionList() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // 备份
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        defer {
            Task {
                try? await SystemProxyKit.setProxy(originalConfig, for: serviceName)
            }
        }

        // 设置例外列表
        var testConfig = originalConfig
        testConfig.exceptionList = ["localhost", "127.0.0.1", "*.local", "192.168.*"]
        testConfig.excludeSimpleHostnames = true

        try await SystemProxyKit.setProxy(testConfig, for: serviceName)

        // 验证
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.excludeSimpleHostnames)
        #expect(verifyConfig.exceptionList.contains("localhost"))
        #expect(verifyConfig.exceptionList.contains("*.local"))
    }

    @Test("Convenience method setHTTPProxy works")
    func convenienceSetHTTPProxy() async throws {
        if skipIfNotRoot() { return }
        let serviceName = try await getTestServiceName()

        // 备份
        let originalConfig = try await SystemProxyKit.current(for: serviceName)

        defer {
            Task {
                try? await SystemProxyKit.setProxy(originalConfig, for: serviceName)
            }
        }

        // 使用便利方法
        try await SystemProxyKit.setHTTPProxy(host: "127.0.0.1", port: 19999, for: serviceName)

        // 验证
        let verifyConfig = try await SystemProxyKit.current(for: serviceName)

        #expect(verifyConfig.httpProxy?.host == "127.0.0.1")
        #expect(verifyConfig.httpProxy?.port == 19999)
        #expect(verifyConfig.httpsProxy?.host == "127.0.0.1")
        #expect(verifyConfig.httpsProxy?.port == 19999)
    }
}

// MARK: - Test Tags

extension Tag {
    /// Tests that require root/admin privileges
    @Tag static var privileged: Self
}
