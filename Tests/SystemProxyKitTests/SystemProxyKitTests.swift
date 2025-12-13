//
//  SystemProxyKitTests.swift
//  SystemProxyKitTests
//
//  Created by SystemProxyKit
//

import Foundation
@testable import SystemProxyKit
import Testing

// MARK: - ProxyServer Tests

@Suite("ProxyServer Tests")
struct ProxyServerTests {
    @Test("Initialize with all parameters")
    func initWithAllParameters() {
        let proxy = ProxyServer(
            host: "127.0.0.1",
            port: 7890,
            isEnabled: true,
            username: "user",
            password: "pass"
        )

        #expect(proxy.host == "127.0.0.1")
        #expect(proxy.port == 7890)
        #expect(proxy.isEnabled)
        #expect(proxy.username == "user")
        #expect(proxy.password == "pass")
        #expect(proxy.hasAuthentication)
    }

    @Test("Initialize without authentication")
    func initWithoutAuth() {
        let proxy = ProxyServer(host: "localhost", port: 8080)

        #expect(!proxy.hasAuthentication)
        #expect(proxy.username == nil)
        #expect(proxy.password == nil)
    }

    @Test("Equatable conformance")
    func equatable() {
        let proxy1 = ProxyServer(host: "127.0.0.1", port: 7890)
        let proxy2 = ProxyServer(host: "127.0.0.1", port: 7890)
        let proxy3 = ProxyServer(host: "127.0.0.1", port: 8080)

        #expect(proxy1 == proxy2)
        #expect(proxy1 != proxy3)
    }
}

// MARK: - PACConfiguration Tests

@Suite("PACConfiguration Tests")
struct PACConfigurationTests {
    @Test("Initialize with URL")
    func initWithURL() {
        let url = URL(string: "http://example.com/proxy.pac")!
        let pac = PACConfiguration(url: url, isEnabled: true)

        #expect(pac.url == url)
        #expect(pac.isEnabled)
    }

    @Test("Initialize from URL string")
    func initFromString() {
        let pac = PACConfiguration(urlString: "http://example.com/proxy.pac")

        #expect(pac != nil)
        #expect(pac?.url.absoluteString == "http://example.com/proxy.pac")
    }

    @Test("Initialize with invalid URL returns nil")
    func initInvalidURL() {
        // Empty string is invalid for URL
        let pac = PACConfiguration(urlString: "")

        #expect(pac == nil)
    }
}

// MARK: - RetryPolicy Tests

@Suite("RetryPolicy Tests")
struct RetryPolicyTests {
    @Test("Preset policies have correct values")
    func presets() {
        #expect(RetryPolicy.none.maxRetries == 0)
        #expect(RetryPolicy.default.maxRetries == 3)
        #expect(RetryPolicy.aggressive.maxRetries == 5)
    }

    @Test("Delay calculation with exponential backoff")
    func delayCalculation() {
        let policy = RetryPolicy(maxRetries: 3, delay: 1.0, backoffMultiplier: 2.0)

        #expect(policy.delayForAttempt(0) == 0)
        #expect(policy.delayForAttempt(1) == 1.0)
        #expect(policy.delayForAttempt(2) == 2.0)
        #expect(policy.delayForAttempt(3) == 4.0)
    }
}

// MARK: - ProxyConfiguration Tests

@Suite("ProxyConfiguration Tests")
struct ProxyConfigurationTests {
    @Test("Empty configuration has no proxies enabled")
    func emptyConfiguration() {
        let config = ProxyConfiguration.empty

        #expect(!config.autoDiscoveryEnabled)
        #expect(config.autoConfigURL == nil)
        #expect(config.httpProxy == nil)
        #expect(config.httpsProxy == nil)
        #expect(config.socksProxy == nil)
        #expect(!config.hasAnyProxyEnabled)
    }

    @Test("Configuration with HTTP proxy")
    func withHTTPProxy() {
        let proxy = ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true)
        let config = ProxyConfiguration(httpProxy: proxy)

        #expect(config.hasManualProxyEnabled)
        #expect(config.hasAnyProxyEnabled)
        #expect(!config.hasAutoProxyEnabled)
    }

    @Test("Configuration with PAC")
    func withPAC() {
        let pac = PACConfiguration(url: URL(string: "http://example.com/proxy.pac")!, isEnabled: true)
        let config = ProxyConfiguration(autoConfigURL: pac)

        #expect(config.hasAutoProxyEnabled)
        #expect(config.hasAnyProxyEnabled)
        #expect(!config.hasManualProxyEnabled)
    }

    @Test("Disable all proxies")
    func disableAll() {
        var config = ProxyConfiguration(
            autoDiscoveryEnabled: true,
            httpProxy: ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true)
        )

        #expect(config.hasAnyProxyEnabled)

        config.disableAllProxies()

        #expect(!config.autoDiscoveryEnabled)
        #expect(!(config.httpProxy?.isEnabled ?? true))
    }
}

// MARK: - SC Dictionary Mapping Tests

@Suite("SC Dictionary Mapping Tests")
struct SCDictionaryMappingTests {
    @Test("Convert ProxyConfiguration to SC Dictionary")
    func toSCDictionary() {
        let proxy = ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true)
        let config = ProxyConfiguration(httpProxy: proxy)

        let dict = config.toSCDictionary()

        #expect(dict[SCProxyKeys.httpEnable] as? Int == 1)
        #expect(dict[SCProxyKeys.httpProxy] as? String == "127.0.0.1")
        #expect(dict[SCProxyKeys.httpPort] as? Int == 7890)
    }

    @Test("Create ProxyConfiguration from SC Dictionary")
    func fromSCDictionary() {
        let dict: [String: Any] = [
            SCProxyKeys.httpEnable: 1,
            SCProxyKeys.httpProxy: "192.168.1.1",
            SCProxyKeys.httpPort: 8080,
            SCProxyKeys.httpsEnable: 0,
            SCProxyKeys.excludeSimpleHostnames: 1,
            SCProxyKeys.exceptionsList: ["localhost", "*.local"],
        ]

        let config = ProxyConfiguration(fromSCDictionary: dict)

        #expect(config.httpProxy != nil)
        #expect(config.httpProxy?.host == "192.168.1.1")
        #expect(config.httpProxy?.port == 8080)
        #expect(config.httpProxy?.isEnabled == true)
        #expect(config.excludeSimpleHostnames)
        #expect(config.exceptionList == ["localhost", "*.local"])
    }

    @Test("Round-trip conversion preserves data")
    func roundTrip() {
        let original = ProxyConfiguration(
            autoDiscoveryEnabled: true,
            autoConfigURL: PACConfiguration(url: URL(string: "http://example.com/pac")!, isEnabled: true),
            httpProxy: ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true),
            httpsProxy: ProxyServer(host: "127.0.0.1", port: 7890, isEnabled: true),
            socksProxy: ProxyServer(host: "127.0.0.1", port: 1080, isEnabled: false),
            excludeSimpleHostnames: true,
            exceptionList: ["localhost", "192.168.*"]
        )

        let dict = original.toSCDictionary()
        let restored = ProxyConfiguration(fromSCDictionary: dict)

        // Basic property validation
        #expect(original.autoDiscoveryEnabled == restored.autoDiscoveryEnabled)
        #expect(original.excludeSimpleHostnames == restored.excludeSimpleHostnames)
        #expect(original.exceptionList == restored.exceptionList)

        // Proxy server validation
        #expect(original.httpProxy?.host == restored.httpProxy?.host)
        #expect(original.httpProxy?.port == restored.httpProxy?.port)
        #expect(original.httpProxy?.isEnabled == restored.httpProxy?.isEnabled)
    }
}

// MARK: - SystemProxyError Tests

@Suite("SystemProxyError Tests")
struct SystemProxyErrorTests {
    @Test(
        "Error has description",
        arguments: [
            SystemProxyError.preferencesCreationFailed,
            SystemProxyError.lockFailed,
            SystemProxyError.serviceNotFound(name: "Wi-Fi"),
            SystemProxyError.commitFailed,
            SystemProxyError.applyFailed,
        ]
    )
    func errorHasDescription(_ error: SystemProxyError) {
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }
}
