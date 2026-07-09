//
//  HomeStore.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 28/06/26.
//

import HomeKit
import Combine
import SwiftUI
import os

private let hkLog = Logger(subsystem: "ElectricityBill", category: "HomeKit")

/// Drives an in-app "Add Accessory" experience using the HomeKit framework, so
/// users can discover, pair, and control the ESP32 (HomeSpan) accessory without
/// opening Apple's Home app. The accessory still lives in the shared HomeKit
/// database, and iOS performs the actual secure pairing (setup code prompt).
class HomeStore: NSObject, ObservableObject {
    let homeManager = HMHomeManager()
    private let browser = HMAccessoryBrowser()

    @Published var homes: [HMHome] = []
    @Published var homeLocal: [Home] = []
    @Published var primaryHome: HMHome?
    /// Unpaired accessories found on the local network / BLE.
    @Published var foundAccessories: [HMAccessory] = []
    /// Accessories already paired into the primary home.
    @Published var pairedAccessories: [HMAccessory] = []
    @Published var isSearching = false
    @Published var statusMessage: String?
    @Published var isLoaded: Bool = false
    /// Set the moment an accessory finishes pairing via `add(_:)` (a genuine
    /// user action) — not on the initial load of already-paired devices.
    /// Views observe this to auto-dismiss the "Add Accessory" flow.
    @Published var lastPairedAccessoryID: UUID?

    override init() {
        super.init()
        homeManager.delegate = self
        browser.delegate = self
    }

    // MARK: - Home management

    /// Returns the primary home, creating one if the user has none yet.
    func ensurePrimaryHome(completion: ((HMHome?) -> Void)? = nil) {
        if let home = homeManager.primaryHome ?? homeManager.homes.first {
            primaryHome = home
            refreshPaired()
            completion?(home)
            return
        }
        homeManager.addHome(withName: "My Home") { [weak self] home, error in
            if let error {
                hkLog.error("addHome failed: \(error.localizedDescription, privacy: .public)")
                self?.statusMessage = "Couldn't create home: \(error.localizedDescription)"
                completion?(nil)
                return
            }
            if let home {
                self?.homeManager.updatePrimaryHome(home) { _ in }
                self?.primaryHome = home
                self?.refreshPaired()
            }
            completion?(home)
        }
    }

    private func refreshPaired() {
        guard let home = primaryHome else { pairedAccessories = []; return }
        pairedAccessories = home.accessories
        home.accessories.forEach(observe)
    }

    // MARK: - Discovery

    func startSearch() {
        foundAccessories = []
        isSearching = true
        statusMessage = nil
        browser.startSearchingForNewAccessories()
        hkLog.info("started searching for new accessories")
    }

    func stopSearch() {
        isSearching = false
        browser.stopSearchingForNewAccessories()
    }

    // MARK: - Pairing

    /// Pairs an accessory into the primary home. iOS presents its secure setup-code
    /// prompt automatically (enter the HomeSpan code, e.g. 11223344).
    func add(_ accessory: HMAccessory) {
        ensurePrimaryHome { [weak self] home in
            guard let self, let home else { return }
            hkLog.info("adding accessory \(accessory.name, privacy: .public)")
            home.addAccessory(accessory) { error in
                if let error {
                    hkLog.error("addAccessory failed: \(error.localizedDescription, privacy: .public)")
                    self.statusMessage = "Pairing failed: \(error.localizedDescription)"
                    return
                }
                home.assignAccessory(accessory, to: home.roomForEntireHome()) { _ in }
                self.observe(accessory)
                self.foundAccessories.removeAll { $0.uniqueIdentifier == accessory.uniqueIdentifier }
                self.refreshPaired()
                self.lastPairedAccessoryID = accessory.uniqueIdentifier
                self.statusMessage = "Added \(accessory.name)"
            }
        }
    }

    // MARK: - Control (Lightbulb power state)

    func powerCharacteristic(for accessory: HMAccessory) -> HMCharacteristic? {
        // Both Lightbulb and Outlet expose the same PowerState characteristic.
        // The power meter is an Outlet, so it must be included or its lamp
        // can't be toggled from the app.
        for service in accessory.services
        where service.serviceType == HMServiceTypeLightbulb
           || service.serviceType == HMServiceTypeOutlet {
            for c in service.characteristics where c.characteristicType == HMCharacteristicTypePowerState {
                return c
            }
        }
        return nil
    }

    func isOn(_ accessory: HMAccessory) -> Bool {
        (powerCharacteristic(for: accessory)?.value as? Bool) ?? false
    }

    func setPower(_ on: Bool, for accessory: HMAccessory) {
        guard let c = powerCharacteristic(for: accessory) else { return }
        c.writeValue(on) { [weak self] error in
            if let error {
                hkLog.error("writeValue failed: \(error.localizedDescription, privacy: .public)")
                self?.statusMessage = "Couldn't toggle \(accessory.name)"
            }
            self?.objectWillChange.send()
        }
    }

    /// Start receiving live updates for an accessory's power state.
    private func observe(_ accessory: HMAccessory) {
        accessory.delegate = self
        guard let c = powerCharacteristic(for: accessory) else { return }
        c.enableNotification(true) { _ in }
        c.readValue { [weak self] _ in self?.objectWillChange.send() }
    }
}

// MARK: - HMHomeManagerDelegate

extension HomeStore: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        DispatchQueue.main.async {
            self.homes = manager.homes
            self.homeLocal = manager.homes.map {
                Home(id: $0.uniqueIdentifier, homeName: $0.name, priceperKwh: 0)
            }
            self.primaryHome = manager.primaryHome ?? manager.homes.first
            self.refreshPaired()
            self.isLoaded = true
        }
    }
}

// MARK: - HMAccessoryBrowserDelegate

extension HomeStore: HMAccessoryBrowserDelegate {
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        hkLog.info("didFindNewAccessory: \(accessory.name, privacy: .public)")
        if !foundAccessories.contains(where: { $0.uniqueIdentifier == accessory.uniqueIdentifier }) {
            foundAccessories.append(accessory)
        }
    }
    
//    func createHome(homeName: String) -> [String]{
//        var errMsg = ["", ""]
//        homeManager.addHome(withName: homeName){ [weak self] (newHome, error) in
//            if let error = error {
//                errMsg = ["err", error.localizedDescription]
//                return
//            }
//            if let newHome = newHome {
//                errMsg = ["success", "Successfully added home: \(newHome.name)"]
//            }
//        }
//        
//        return errMsg
//        
//        func accessoryBrowser(_ browser: HMAccessoryBrowser, didRemoveNewAccessory accessory: HMAccessory) {
//            foundAccessories.removeAll { $0.uniqueIdentifier == accessory.uniqueIdentifier }
//        }
//    }

    func createHome(homeName: String, completion: @escaping (Result<HMHome, Error>) -> Void) {
        homeManager.addHome(withName: homeName) { newHome, error in
            if let error {
                hkLog.error("addHome failed: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let newHome else {
                let unknownError = NSError(
                    domain: "HomeStore", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Home creation returned no home and no error"]
                )
                DispatchQueue.main.async { completion(.failure(unknownError)) }
                return
            }
            // homeLocal TIDAK perlu di-append manual di sini —
            // homeManagerDidUpdateHomes akan otomatis terpanggil ulang oleh HomeKit
            // dan mengisi ulang homeLocal dari manager.homes (sudah termasuk home baru ini).
            DispatchQueue.main.async { completion(.success(newHome)) }
        }
    }
}

// MARK: - HMAccessoryDelegate

extension HomeStore: HMAccessoryDelegate {
    func accessory(_ accessory: HMAccessory, service: HMService,
                   didUpdateValueFor characteristic: HMCharacteristic) {
        objectWillChange.send()
    }

    func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        objectWillChange.send()
    }
}
