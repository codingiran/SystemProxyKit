//
//  GetCommand.swift
//  sysproxy
//
//  Get current proxy configuration
//

import ArgumentParser
import Foundation
import SystemProxyKit

struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Get current proxy configuration for a network interface."
    )

    @Argument(help: "Network interface name (e.g., 'Wi-Fi', 'Ethernet').")
    var interface: String

    @Flag(name: .shortAndLong, help: "Output in JSON format.")
    var json: Bool = false

    func run() async throws {
        let config = try await SystemProxyKit.getProxy(for: interface)

        if json {
            printJSON(config)
        } else {
            printHumanReadable(config)
        }
    }

    private func printHumanReadable(_ config: ProxyConfiguration) {
        print("Proxy Configuration for '\(interface)':")
        print(String(repeating: "-", count: 50))

        // Auto Discovery
        print("\n[Auto Discovery]")
        print("  Auto Proxy Discovery (WPAD): \(config.autoDiscoveryEnabled ? "Enabled" : "Disabled")")

        // PAC
        print("\n[Automatic Proxy Configuration (PAC)]")
        if let pac = config.autoConfigURL, pac.isEnabled {
            print("  Status: Enabled")
            print("  URL: \(pac.url.absoluteString)")
        } else {
            print("  Status: Disabled")
        }

        // HTTP Proxy
        print("\n[HTTP Proxy]")
        if let http = config.httpProxy, http.isEnabled {
            print("  Status: Enabled")
            print("  Server: \(http.host):\(http.port)")
            if let username = http.username {
                print("  Username: \(username)")
            }
        } else {
            print("  Status: Disabled")
        }

        // HTTPS Proxy
        print("\n[HTTPS Proxy]")
        if let https = config.httpsProxy, https.isEnabled {
            print("  Status: Enabled")
            print("  Server: \(https.host):\(https.port)")
            if let username = https.username {
                print("  Username: \(username)")
            }
        } else {
            print("  Status: Disabled")
        }

        // SOCKS Proxy
        print("\n[SOCKS Proxy]")
        if let socks = config.socksProxy, socks.isEnabled {
            print("  Status: Enabled")
            print("  Server: \(socks.host):\(socks.port)")
            if let username = socks.username {
                print("  Username: \(username)")
            }
        } else {
            print("  Status: Disabled")
        }

        // Exceptions
        print("\n[Bypass Settings]")
        print("  Exclude Simple Hostnames: \(config.excludeSimpleHostnames ? "Yes" : "No")")
        if config.exceptionList.isEmpty {
            print("  Exception List: (none)")
        } else {
            print("  Exception List:")
            for exception in config.exceptionList {
                print("    - \(exception)")
            }
        }
    }

    private func printJSON(_ config: ProxyConfiguration) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(config)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            print("Error encoding configuration to JSON: \(error)")
        }
    }
}
