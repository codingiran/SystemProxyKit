//
//  DisableCommand.swift
//  sysproxy
//
//  Disable proxy configuration
//

import ArgumentParser
import SystemProxyKit

struct Disable: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Disable all proxies for a network interface.",
        discussion: """
        Disables all proxy settings (HTTP, HTTPS, SOCKS, PAC) for the specified
        network interface. Requires root privileges.

        Examples:
          sudo sysproxy disable Wi-Fi
          sudo sysproxy disable --all
        """
    )

    @Argument(help: "Network interface name (e.g., 'Wi-Fi', 'Ethernet'). Ignored if --all is specified.")
    var interface: String?

    @Flag(name: .shortAndLong, help: "Disable proxies for all enabled network services.")
    var all: Bool = false

    func validate() throws {
        if !all, interface == nil {
            throw ValidationError("Please specify an interface name or use --all flag.")
        }
    }

    func run() async throws {
        if all {
            try await disableAll()
        } else if let interface = interface {
            try await disableSingle(interface: interface)
        }
    }

    private func disableSingle(interface: String) async throws {
        try await SystemProxyKit.disableAllProxies(for: interface)
        print("✓ All proxies disabled for '\(interface)'")
    }

    private func disableAll() async throws {
        let services = try await SystemProxyKit.allServicesInfo()
        let enabledServices = services.filter { $0.isEnabled }

        if enabledServices.isEmpty {
            print("No enabled network services found.")
            return
        }

        var successCount = 0
        var failedServices: [(name: String, error: Error)] = []

        for service in enabledServices {
            do {
                try await SystemProxyKit.disableAllProxies(for: service.name)
                successCount += 1
                print("✓ Disabled proxies for '\(service.name)'")
            } catch {
                failedServices.append((service.name, error))
                print("✗ Failed to disable proxies for '\(service.name)': \(error)")
            }
        }

        print()
        if failedServices.isEmpty {
            print("Successfully disabled proxies for all \(successCount) enabled service(s).")
        } else {
            print("Completed: \(successCount) succeeded, \(failedServices.count) failed.")
        }
    }
}
