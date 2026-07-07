//
//  DeviceUsageRecord.swift
//  ElectricityBill
//
//  Created by Keira on 07/07/26.
//

import Foundation
import SwiftData

@Model
class DeviceUsageRecord {
    var id: UUID
    var month: Date
    var durationMinutes: Int
    var kWh: Double
    var device: DeviceModel?

    init(
        id: UUID = UUID(),
        month: Date,
        durationMinutes: Int,
        kWh: Double,
        device: DeviceModel? = nil
    ) {
        self.id = id
        self.month = month
        self.durationMinutes = durationMinutes
        self.kWh = kWh
        self.device = device
    }
}
