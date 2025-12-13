//
//  SysProxy.swift
//  sysproxy
//
//  Command-line interface for SystemProxyKit
//

import ArgumentParser
import SystemProxyKit

@main
struct SysProxy: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sysproxy",
        abstract: "A command-line tool for managing macOS system proxy settings.",
        discussion: """
        sysproxy provides commands to view and modify system proxy settings
        for network interfaces on macOS.

        Note: Modifying proxy settings requires root privileges.
        Use 'sudo sysproxy' for set/disable commands.
        """,
        version: "sysproxy \(version)",
        subcommands: [
            Get.self,
            Set.self,
            List.self,
            Disable.self,
        ],
        defaultSubcommand: List.self
    )
}
