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
    var startTime: Int
    var endTime: Int?
    var kWh: Double
    var device: DeviceModel?

    init(
        id: UUID = UUID(),
        month: Date,
        startTime: Int,
        endTime: Int?,
        kWh: Double,
        device: DeviceModel? = nil
    ) {
        self.id = id
        self.month = month
        self.startTime = startTime
        self.endTime = endTime
        self.kWh = kWh
        self.device = device
    }
}
