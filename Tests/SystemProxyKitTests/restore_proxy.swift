#!/usr/bin/env swift

import Foundation
import SystemConfiguration

// Directly disable all proxies for Wi-Fi
func disableProxies() {
    guard let prefs = SCPreferencesCreate(nil, "RestoreTool" as CFString, nil) else {
        print("❌ Failed to create preferences")
        return
    }

    guard SCPreferencesLock(prefs, true) else {
        print("❌ Failed to lock preferences")
        return
    }

    defer {
        SCPreferencesUnlock(prefs)
    }

    // Find Wi-Fi service
    guard let services = SCNetworkServiceCopyAll(prefs) as? [SCNetworkService] else {
        print("❌ Failed to get services")
        return
    }

    var found = false
    for service in services {
        guard let name = SCNetworkServiceGetName(service) as String? else { continue }

        if name == "Wi-Fi" || name.contains("Wi-Fi") {
            found = true
            print("📍 Found service: \(name)")

            guard let proxyProtocol = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeProxies) else {
                print("❌ Failed to get proxy protocol")
                continue
            }

            // Disable all proxies
            let config: [String: Any] = [
                kSCPropNetProxiesHTTPEnable as String: 0,
                kSCPropNetProxiesHTTPSEnable as String: 0,
                kSCPropNetProxiesSOCKSEnable as String: 0,
                kSCPropNetProxiesProxyAutoConfigEnable as String: 0,
                kSCPropNetProxiesProxyAutoDiscoveryEnable as String: 0,
            ]

            guard SCNetworkProtocolSetConfiguration(proxyProtocol, config as CFDictionary) else {
                print("❌ Failed to set configuration")
                continue
            }

            print("✅ Disabled all proxies for \(name)")
        }
    }

    if !found {
        print("⚠️ Wi-Fi service not found")
        return
    }

    guard SCPreferencesCommitChanges(prefs) else {
        print("❌ Failed to commit changes")
        return
    }

    guard SCPreferencesApplyChanges(prefs) else {
        print("❌ Failed to apply changes")
        return
    }

    print("✅ Successfully restored proxy settings!")
}

disableProxies()
