//
//  Home.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 02/07/26.
//

import SwiftData
import HomeKit

@Model
class Home{
    var id: UUID
    var VACapacity: Int?
    var homeName: String
    var priceperKwh: Double?
    
    @Relationship(deleteRule: .cascade, inverse: \DeviceModel.home)
    var devices: [DeviceModel] = []
    
    init(id : UUID, VACapacity: Int = 0, homeName: String, priceperKwh: Double) {
        self.id = id
        self.VACapacity = VACapacity
        self.homeName = homeName
        self.priceperKwh = priceperKwh
    }
    
    func wattLimit() -> Double {
        return Double(VACapacity ?? 0) * 0.8
    }
    
    
    func getMonthlySummary() -> monthlyUsageSummary {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        func totalKwh(for month: Date) -> Double {
            var totalKwh = 0.0
            for device in devices{
                let deviceHrDuration = device.getTotalDuration(month: month, unit: .hr)
                let deviceTotalKwH = Double(device.VARating!) * 0.8 * deviceHrDuration / 1000
                totalKwh += deviceTotalKwH
            }
            
            return totalKwh
        }
        
        let currentKwh = totalKwh(for: now)
        let previousKwh = totalKwh(for: lastMonth)
//
        return monthlyUsageSummary(
            currentmonthkwh: currentKwh,
            previousmonthkwh: previousKwh,
            currentmonthSpend: currentKwh * priceperKwh!,
            previousmonthSpend: previousKwh * priceperKwh!
        )
    }
    
}



