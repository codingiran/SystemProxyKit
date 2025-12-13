//
//  IntegrationTests.swift
//  SystemProxyKitTests
//
//  Integration tests that interact with real system configuration.
//  These tests are safe to run without special permissions.
//

import Foundation
@testable import SystemProxyKit
import Testing

// MARK: - Network Service Discovery Tests

@Suite("Network Service Discovery")
struct NetworkServiceDiscoveryTests {
    @Test("Can list all available network services")
    func listAvailableServices() async throws {
        let services = try await SystemProxyKit.availableServices()

        // 任何 macOS 系统应该至少有一个网络服务
        #expect(!services.isEmpty, "Expected at least one network service")

        // 打印发现的服务（调试用）
        print("Found \(services.count) network services: \(services)")
    }

    @Test("Can get detailed info for all services")
    func getServicesInfo() async throws {
        let servicesInfo = try await SystemProxyKit.allServicesInfo()

        #expect(!servicesInfo.isEmpty, "Expected at least one network service")

        for info in servicesInfo {
            // 每个服务应该有名称
            #expect(!info.name.isEmpty, "Service name should not be empty")
            print("Service: \(info.name), BSD: \(info.bsdName ?? "N/A"), Type: \(info.interfaceType ?? "N/A"), Enabled: \(info.isEnabled)")
        }
    }

    @Test("Common network services exist")
    func commonServicesExist() async throws {
        let services = try await SystemProxyKit.availableServices()

        // 检查是否存在常见的网络服务（至少一个）
        let commonServices = ["Wi-Fi", "Ethernet", "USB 10/100/1000 LAN", "Thunderbolt Bridge"]
        let hasCommonService = services.contains { commonServices.contains($0) }

        // 不强制要求，只是打印信息
        if hasCommonService {
            print("Found common network service")
        } else {
            print("No common network service found, available: \(services)")
        }
    }
}

// MARK: - Proxy Configuration Read Tests

@Suite("Proxy Configuration Reading")
struct ProxyConfigurationReadTests {
    /// 尝试获取第一个可用网络服务的名称
    private func getFirstAvailableService() async throws -> String {
        let services = try await SystemProxyKit.availableServices()
        guard let first = services.first else {
            throw SystemProxyError.unknown(message: "No network service available for testing")
        }
        return first
    }

    @Test("Can read proxy configuration from first available service")
    func readFirstServiceConfig() async throws {
        let serviceName = try await getFirstAvailableService()
        let config = try await SystemProxyKit.current(for: serviceName)

        // 配置应该是有效的（不管具体内容）
        print("Configuration for '\(serviceName)': \(config)")
    }

    @Test("Can read Wi-Fi proxy configuration if available")
    func readWiFiConfig() async throws {
        let services = try await SystemProxyKit.availableServices()

        guard services.contains("Wi-Fi") else {
            print("Wi-Fi service not available, skipping test")
            return
        }

        let config = try await SystemProxyKit.current(for: "Wi-Fi")

        print("Wi-Fi proxy configuration:")
        print("  - Auto Discovery: \(config.autoDiscoveryEnabled)")
        print("  - PAC URL: \(config.autoConfigURL?.url.absoluteString ?? "none")")
        print("  - HTTP Proxy: \(config.httpProxy?.description ?? "none")")
        print("  - HTTPS Proxy: \(config.httpsProxy?.description ?? "none")")
        print("  - SOCKS Proxy: \(config.socksProxy?.description ?? "none")")
        print("  - Exclude Simple Hostnames: \(config.excludeSimpleHostnames)")
        print("  - Exception List: \(config.exceptionList)")
    }

    @Test("Reading non-existent service throws serviceNotFound error")
    func readNonExistentService() async {
        do {
            _ = try await SystemProxyKit.current(for: "NonExistentService12345")
            Issue.record("Expected serviceNotFound error")
        } catch let error as SystemProxyError {
            guard case let .serviceNotFound(name) = error else {
                Issue.record("Expected serviceNotFound, got \(error)")
                return
            }
            #expect(name == "NonExistentService12345")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Can read configuration multiple times without issues")
    func multipleReads() async throws {
        let serviceName = try await getFirstAvailableService()

        // 连续读取多次
        for i in 1 ... 5 {
            let config = try await SystemProxyKit.current(for: serviceName)
            print("Read #\(i): hasAnyProxyEnabled = \(config.hasAnyProxyEnabled)")
        }
    }

    @Test("Concurrent reads are safe")
    func concurrentReads() async throws {
        let serviceName = try await getFirstAvailableService()

        // 并发读取
        await withTaskGroup(of: ProxyConfiguration?.self) { group in
            for _ in 1 ... 10 {
                group.addTask {
                    try? await SystemProxyKit.current(for: serviceName)
                }
            }

            var successCount = 0
            for await config in group {
                if config != nil {
                    successCount += 1
                }
            }

            #expect(successCount == 10, "All concurrent reads should succeed")
        }
    }
}

// MARK: - SystemProxyManager Instance Tests

@Suite("SystemProxyManager Instance")
struct SystemProxyManagerInstanceTests {
    @Test("Can create manager with custom app identifier")
    func createWithCustomIdentifier() async throws {
        let manager = SystemProxyManager(appIdentifier: "com.test.SystemProxyKitTests")
        let services = try await manager.availableServices()

        #expect(!services.isEmpty)
    }

    @Test("Shared manager works correctly")
    func sharedManager() async throws {
        let services1 = try await SystemProxyKit.shared.availableServices()
        let services2 = try await SystemProxyKit.availableServices()

        #expect(services1 == services2, "Shared manager should return same results")
    }
}
