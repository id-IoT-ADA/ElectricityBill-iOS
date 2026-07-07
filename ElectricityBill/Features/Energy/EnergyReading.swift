//
//  EnergyReading.swift
//  ElectricityBill
//
//  Created by Ikhwan on 07/07/26.
//

import Foundation
import SwiftData

@Model
class EnergyReading {
    var deviceID: UUID = UUID()
    var voltage: Double = 0.0
    var current: Double = 0.0 //Ampere
    var watt: Double = 0.0
    var kWh: Double = 0.0
    var timestamp: Date = Date()
    
    init(deviceID: UUID, voltage: Double, current: Double, watt: Double, kWh: Double, timestamp: Date) {
        self.deviceID = deviceID
        self.voltage = voltage
        self.current = current
        self.watt = watt
        self.kWh = kWh
        self.timestamp = timestamp
    }
}
