//
//  ListCommand.swift
//  sysproxy
//
//  List available network services
//

import ArgumentParser
import SystemProxyKit

struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List all available network services."
    )

    @Flag(name: .shortAndLong, help: "Show only enabled services.")
    var enabledOnly: Bool = false

    @Flag(name: .shortAndLong, help: "Show detailed service information.")
    var verbose: Bool = false

    func run() async throws {
        let services = try await SystemProxyKit.allServicesInfo()

        let filteredServices = enabledOnly ? services.filter { $0.isEnabled } : services

        if filteredServices.isEmpty {
            print("No network services found.")
            return
        }

        if verbose {
            print("Network Services:")
            print(String(repeating: "-", count: 60))
            for service in filteredServices {
                let status = service.isEnabled ? "✓ Enabled" : "✗ Disabled"
                print("  \(service.name)")
                print("    Status: \(status)")
                if let interfaceType = service.interfaceType {
                    print("    Interface Type: \(interfaceType)")
                }
                if let bsdName = service.bsdName {
                    print("    BSD Name: \(bsdName)")
                }
                print()
            }
        } else {
            print("Available Network Services:")
            for service in filteredServices {
                let status = service.isEnabled ? "✓" : "✗"
                print("  \(status) \(service.name)")
            }
        }

        print("\nTotal: \(filteredServices.count) service(s)")
    }
}
