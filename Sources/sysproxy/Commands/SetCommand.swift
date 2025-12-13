//
//  SetCommand.swift
//  sysproxy
//
//  Set proxy configuration
//

import ArgumentParser
import Foundation
import SystemProxyKit

struct Set: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Set proxy configuration for a network interface.",
        discussion: """
        Set various types of proxy configurations. Requires root privileges.

        Examples:
          sudo sysproxy set http --host 127.0.0.1 --port 7890 --interface Wi-Fi
          sudo sysproxy set socks --host 127.0.0.1 --port 1080 --interface Wi-Fi
          sudo sysproxy set pac --url http://example.com/proxy.pac --interface Wi-Fi
        """,
        subcommands: [
            HTTP.self,
            HTTPS.self,
            SOCKS.self,
            PAC.self,
        ]
    )
}

// MARK: - HTTP Proxy

extension Set {
    struct HTTP: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "http",
            abstract: "Set HTTP proxy."
        )

        @Option(name: .shortAndLong, help: "Proxy server host.")
        var host: String

        @Option(name: .shortAndLong, help: "Proxy server port.")
        var port: Int

        @Option(name: .shortAndLong, help: "Network interface name.")
        var interface: String

        @Option(name: .long, help: "Proxy authentication username.")
        var username: String?

        @Option(name: .long, help: "Proxy authentication password.")
        var password: String?

        @Flag(name: .long, help: "Also set HTTPS proxy with the same settings.")
        var withHTTPS: Bool = false

        func run() async throws {
            var config = try await SystemProxyKit.getProxy(for: interface)

            let proxy = ProxyServer(
                host: host,
                port: port,
                isEnabled: true,
                username: username,
                password: password
            )

            config.httpProxy = proxy

            if withHTTPS {
                config.httpsProxy = proxy
            }

            try await SystemProxyKit.setProxy(config, for: interface)

            print("✓ HTTP proxy set to \(host):\(port) for '\(interface)'")
            if withHTTPS {
                print("✓ HTTPS proxy also set to \(host):\(port)")
            }
        }
    }
}

// MARK: - HTTPS Proxy

extension Set {
    struct HTTPS: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "https",
            abstract: "Set HTTPS proxy."
        )

        @Option(name: .shortAndLong, help: "Proxy server host.")
        var host: String

        @Option(name: .shortAndLong, help: "Proxy server port.")
        var port: Int

        @Option(name: .shortAndLong, help: "Network interface name.")
        var interface: String

        @Option(name: .long, help: "Proxy authentication username.")
        var username: String?

        @Option(name: .long, help: "Proxy authentication password.")
        var password: String?

        func run() async throws {
            var config = try await SystemProxyKit.getProxy(for: interface)

            config.httpsProxy = ProxyServer(
                host: host,
                port: port,
                isEnabled: true,
                username: username,
                password: password
            )

            try await SystemProxyKit.setProxy(config, for: interface)

            print("✓ HTTPS proxy set to \(host):\(port) for '\(interface)'")
        }
    }
}

// MARK: - SOCKS Proxy

extension Set {
    struct SOCKS: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "socks",
            abstract: "Set SOCKS proxy."
        )

        @Option(name: .shortAndLong, help: "Proxy server host.")
        var host: String

        @Option(name: .shortAndLong, help: "Proxy server port.")
        var port: Int

        @Option(name: .shortAndLong, help: "Network interface name.")
        var interface: String

        @Option(name: .long, help: "Proxy authentication username.")
        var username: String?

        @Option(name: .long, help: "Proxy authentication password.")
        var password: String?

        func run() async throws {
            var config = try await SystemProxyKit.getProxy(for: interface)

            config.socksProxy = ProxyServer(
                host: host,
                port: port,
                isEnabled: true,
                username: username,
                password: password
            )

            try await SystemProxyKit.setProxy(config, for: interface)

            print("✓ SOCKS proxy set to \(host):\(port) for '\(interface)'")
        }
    }
}

// MARK: - PAC Proxy

extension Set {
    struct PAC: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "pac",
            abstract: "Set PAC (Proxy Auto-Configuration) URL."
        )

        @Option(name: .shortAndLong, help: "PAC script URL.")
        var url: String

        @Option(name: .shortAndLong, help: "Network interface name.")
        var interface: String

        func run() async throws {
            guard let pacURL = URL(string: url) else {
                throw ValidationError("Invalid URL: \(url)")
            }

            var config = try await SystemProxyKit.getProxy(for: interface)

            config.autoConfigURL = PACConfiguration(
                url: pacURL,
                isEnabled: true
            )

            try await SystemProxyKit.setProxy(config, for: interface)

            print("✓ PAC proxy set to \(url) for '\(interface)'")
        }
    }
}
