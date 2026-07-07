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
    var startTime: Date
    var endTime: Date?
    var kWh: Double
    var device: DeviceModel?

    init(
        id: UUID = UUID(),
        month: Date,
        startTime: Date,
        endTime: Date?,
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

extension DeviceUsageRecord {
    var durationInMinutes: Double {
        guard let endTime else { return 0 }
        return endTime.timeIntervalSince(startTime) / 60
    }
    
    private func estimatedKWh(va: DeviceModel, durationInMinutes: Double) -> Double {
        guard let va = va.VARating, va > 0 else { return 0 }
        let hours = durationInMinutes / 60
        return (Double(va) * hours) / 1000
    }
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


