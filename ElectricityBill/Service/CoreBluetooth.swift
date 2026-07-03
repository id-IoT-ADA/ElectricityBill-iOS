//
//  CoreBluetooth.swift
//  ElectricityBill
//
//  Created by Ikhwan on 02/07/26.
//

import CoreBluetooth
import Combine
import os

private let bleLog = Logger(subsystem: "ElectricityBill", category: "BLE")

enum BLEStatus: Equatable {
    case initializing
    case bluetoothOff
    case permissionDenied
    case unsupported
    case ready
    case scanning
    case connecting
    case connected
    case sending
    case success
    case failed
}

struct WiFiNetwork: Identifiable, Equatable, Decodable {
    let ssid: String
    let rssi: Int
    let secure: Bool

    var id: String { ssid }
}

class BLEProvisioningManager: NSObject, ObservableObject {
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var status: BLEStatus = .initializing
    /// Wi-Fi networks scanned by the connected ESP32 (read from the networks characteristic).
    @Published var availableNetworks: [WiFiNetwork] = []
    /// True once the ESP32's network list has been received (even if it was empty),
    /// so the UI can tell "still scanning" apart from "scan done, no networks".
    @Published var networksLoaded = false

    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var ssidChar: CBCharacteristic?
    private var passChar: CBCharacteristic?
    private var networksChar: CBCharacteristic?
    private var connectTimeoutWork: DispatchWorkItem?

    private let connectTimeout: TimeInterval = 12

    private let serviceUUID  = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    private let ssidUUID     = CBUUID(string: "12345678-1234-1234-1234-123456789ab1")
    private let passUUID     = CBUUID(string: "12345678-1234-1234-1234-123456789ab2")
    private let statusUUID   = CBUUID(string: "12345678-1234-1234-1234-123456789ab3")
    private let networksUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ab4")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        status = .scanning
        centralManager.scanForPeripherals(withServices: [serviceUUID])

        // Optional safety timeout — stop scanning after 15s to save battery
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            guard let self, self.status == .scanning else { return }
            self.centralManager.stopScan()
            if self.status == .scanning { self.status = .ready }
        }
    }

    func stopScan() {
        centralManager.stopScan()
        if status == .scanning { status = .ready }
    }

    func connect(to peripheral: CBPeripheral) {
        bleLog.info("connect(to:) name=\(peripheral.name ?? "nil", privacy: .public) id=\(peripheral.identifier.uuidString, privacy: .public) state=\(peripheral.state.rawValue)")
        targetPeripheral = peripheral
        status = .connecting
        availableNetworks = []
        networksLoaded = false
        centralManager.stopScan()
        centralManager.connect(peripheral)

        // connect(_:) never times out on its own — guard against hanging on .connecting
        connectTimeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.status == .connecting else { return }
            bleLog.error("connect timeout after \(self.connectTimeout)s — no didConnect/didFailToConnect. Cancelling.")
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.status = .failed
        }
        connectTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + connectTimeout, execute: work)
    }

    /// Re-read the ESP32's Wi-Fi scan results (e.g. from a "Rescan" button).
    func refreshNetworks() {
        guard let networksChar, let peripheral = targetPeripheral else { return }
        networksLoaded = false
        peripheral.readValue(for: networksChar)
    }

    func sendCredentials(ssid: String, password: String) {
        guard let ssidChar, let passChar, let peripheral = targetPeripheral else { return }
        status = .sending
        peripheral.writeValue(Data(ssid.utf8), for: ssidChar, type: .withResponse)
        peripheral.writeValue(Data(password.utf8), for: passChar, type: .withResponse)
    }

    func reset() {
        connectTimeoutWork?.cancel()
        if let peripheral = targetPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        targetPeripheral = nil
        ssidChar = nil
        passChar = nil
        networksChar = nil
        availableNetworks = []
        networksLoaded = false
        discoveredDevices.removeAll()
        status = centralManager.state == .poweredOn ? .ready : .initializing
    }
}

extension BLEProvisioningManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bleLog.info("centralManagerDidUpdateState: \(central.state.rawValue)")
        switch central.state {
        case .poweredOn:      status = .ready
        case .poweredOff:     status = .bluetoothOff
        case .unauthorized:   status = .permissionDenied
        case .unsupported:    status = .unsupported
        case .resetting, .unknown: status = .initializing
        @unknown default:     status = .initializing
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                         advertisementData: [String: Any], rssi: NSNumber) {
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            bleLog.info("didDiscover: \(peripheral.name ?? "Unknown", privacy: .public) rssi=\(rssi.intValue) connectable=\(String(describing: advertisementData[CBAdvertisementDataIsConnectable]), privacy: .public)")
            discoveredDevices.append(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        bleLog.info("didConnect — discovering services")
        connectTimeoutWork?.cancel()
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        bleLog.error("didFailToConnect: \(error?.localizedDescription ?? "nil", privacy: .public)")
        connectTimeoutWork?.cancel()
        status = .failed
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        bleLog.error("didDisconnect: \(error?.localizedDescription ?? "nil", privacy: .public) status=\(String(describing: self.status))")
        connectTimeoutWork?.cancel()
        if status != .success {
            status = .failed
        }
    }
}

extension BLEProvisioningManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error { bleLog.error("didDiscoverServices error: \(error.localizedDescription, privacy: .public)") }
        bleLog.info("didDiscoverServices found: \(peripheral.services?.map { $0.uuid.uuidString } ?? [], privacy: .public)")
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            bleLog.error("target service \(self.serviceUUID.uuidString, privacy: .public) not found — failing")
            status = .failed
            return
        }
        peripheral.discoverCharacteristics([ssidUUID, passUUID, statusUUID, networksUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error { bleLog.error("didDiscoverCharacteristics error: \(error.localizedDescription, privacy: .public)") }
        bleLog.info("didDiscoverCharacteristics: \(service.characteristics?.map { $0.uuid.uuidString } ?? [], privacy: .public)")
        for c in service.characteristics ?? [] {
            switch c.uuid {
            case ssidUUID: ssidChar = c
            case passUUID: passChar = c
            case statusUUID: peripheral.setNotifyValue(true, for: c)
            case networksUUID:
                networksChar = c
                peripheral.readValue(for: c) // iOS handles the multi-packet long read automatically
            default: break
            }
        }
        status = .connected
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            bleLog.error("didUpdateValueFor \(characteristic.uuid.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            // A failed networks read must still end the "scanning" state, or the UI spins forever.
            if characteristic.uuid == networksUUID {
                DispatchQueue.main.async { self.networksLoaded = true }
            }
            return
        }
        guard let data = characteristic.value else { return }

        switch characteristic.uuid {
        case networksUUID:
            let networks = (try? JSONDecoder().decode([WiFiNetwork].self, from: data)) ?? []
            bleLog.info("networks received: \(networks.count) — \(networks.map { $0.ssid }, privacy: .public)")
            // Strongest signal first, drop duplicate SSIDs.
            var seen = Set<String>()
            let sorted = networks
                .sorted { $0.rssi > $1.rssi }
                .filter { seen.insert($0.ssid).inserted && !$0.ssid.isEmpty }
            DispatchQueue.main.async {
                self.availableNetworks = sorted
                self.networksLoaded = true
            }

        case statusUUID:
            let value = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async {
                switch value {
                case "connecting": self.status = .sending
                case "success":    self.status = .success
                case "failed":     self.status = .failed
                default: break
                }
            }

        default:
            break
        }
    }
}
