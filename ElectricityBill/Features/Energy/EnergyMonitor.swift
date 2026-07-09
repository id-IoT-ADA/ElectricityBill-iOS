//
//  EnergyMonitor.swift
//  ElectricityBill
//
//  Created by Ikhwan on 07/07/26.
//

import Foundation
import HomeKit
import SwiftData
import Combine

@MainActor
class EnergyMonitor : NSObject, ObservableObject {
    @Published var voltage: Double = 0
    @Published var current: Double = 0
    @Published var watt: Double = 0
    @Published var kWh: Double = 0
    @Published var isOn: Bool = false

    private let accessory: HMAccessory
    private let device: DeviceModel
    private let context: ModelContext
    private var powerChar: HMCharacteristic?
    private var lastPersist = Date.distantPast
    private let persistInterval: TimeInterval = 30

    // Kalibrasi VARating sekali seumur hidup device: setelah accessory mengalirkan
    // arus selama `calibrationWindow` detik, nilai mA saat itu dijadikan VARating
    // dan tidak diperbarui lagi.
    private let calibrationWindow: TimeInterval = 10
    private var currentStartedAt: Date?
    private var didCalibrate: Bool = false
    
    private let energyUUIDs: Set<String> = [
        EveCharacteristic.voltage,
        EveCharacteristic.current,
        EveCharacteristic.watt,
        EveCharacteristic.kWh
    ]
    
    init(accessory: HMAccessory, device: DeviceModel, context: ModelContext) {
        self.accessory = accessory
        self.device = device
        self.context = context
        super.init()
        // Sudah punya VARating (mis. hasil kalibrasi sebelumnya) → jangan kalibrasi lagi.
        self.didCalibrate = (device.VARating ?? 0) != 0
        subscribe()
    }

    /// Menetapkan VARating satu kali dari arus nyata: mulai hitung sejak arus
    /// pertama muncul, lalu setelah `calibrationWindow` detik ambil nilai mA
    /// saat itu (mis. 6.12 → 6). Setelah itu tidak pernah diperbarui lagi.
    private func calibrateIfNeeded() {
        guard !didCalibrate else { return }
        let mA = current * 1000
        guard mA > 0 else { return }            // butuh arus dulu
        if currentStartedAt == nil {
            currentStartedAt = Date()
            return
        }
        guard Date().timeIntervalSince(currentStartedAt!) >= calibrationWindow else { return }
        device.VARating = Int(mA.rounded())
        didCalibrate = true
    }
    
    private func subscribe() {
        accessory.delegate = self

        for service in accessory.services {
            for c in service.characteristics {
                let type = c.characteristicType.uppercased()

                // The On/off switch (lamp control) — keep a reference to write to it.
                if type == HMCharacteristicTypePowerState.uppercased() {
                    powerChar = c
                    c.enableNotification(true) { _ in }
                    c.readValue { _ in }
                    continue
                }

                // Energy readings.
                guard energyUUIDs.contains(type) else { continue }
                c.enableNotification(true) { error in
                    if let error {
                        print("notify gagal:", error.localizedDescription)
                    }
                }
                c.readValue{ _ in }
            }
        }
    }

    func setOn(_ on: Bool) {
        guard let powerChar else { return }
        isOn = on
        powerChar.writeValue(on) { error in
            if let error { print("toggle gagal:", error.localizedDescription) }
        }
    }
    
    private func persist() {
        guard Date().timeIntervalSince(lastPersist) >= persistInterval else { return }
        lastPersist = Date()
        
        let reading = EnergyReading(
            deviceID: accessory.uniqueIdentifier,
            voltage: voltage,
            current: current,
            watt: watt,
            kWh: kWh,
            timestamp: .now
        )
        context.insert(reading)
    }
}

extension EnergyMonitor: HMAccessoryDelegate {
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        let type = characteristic.characteristicType.uppercased()

        // Lamp on/off state.
        if type == HMCharacteristicTypePowerState.uppercased() {
            isOn = (characteristic.value as? Bool) ?? false
            return
        }

        // Energy readings.
        let value = (characteristic.value as? NSNumber)?.doubleValue ?? 0
        switch type {
            case EveCharacteristic.voltage: voltage = value
            case EveCharacteristic.current: current = value
            case EveCharacteristic.watt: watt = value
            case EveCharacteristic.kWh: kWh = value
            default: return
        }
        calibrateIfNeeded()
        persist()
    }
}
