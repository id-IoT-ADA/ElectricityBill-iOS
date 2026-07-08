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
    var startTime: Date
    var endTime: Date?
    var kWh: Double?
    var device: DeviceModel?

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        kWh: Double? = 0.0,
        device: DeviceModel? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.kWh = kWh
        self.device = device
    }
    
}

func formattedDuration(totalDurationMinutes: Double) -> String {
    let totalMinutes = Int(totalDurationMinutes)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
}

struct monthlyUsageSummary {
    let currentmonthkwh: Double
    let previousmonthkwh: Double
    let currentmonthSpend: Double
    let previousmonthSpend: Double

    var percentChange: Double {
        guard previousmonthkwh > 0 else { return 0 }
        return ((previousmonthkwh - currentmonthkwh) / previousmonthkwh) * 100
    }
    
    var rupiahdiff: Double{
        guard previousmonthSpend > 0 else {return 0}
        return (currentmonthSpend - previousmonthSpend)
    }
}


