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
    var month: Int
    var startTime: Date
    var endTime: Date?
//    var kWh: Double
    var device: DeviceModel?

    init(
        id: UUID = UUID(),
        month: Int,
        startTime: Date,
        endTime: Date? = nil,
//        kWh: Double,
        device: DeviceModel? = nil
    ) {
        self.id = id
        self.month = month
        self.startTime = startTime
        self.endTime = endTime
//        self.kWh = kWh
        self.device = device
    }
}
