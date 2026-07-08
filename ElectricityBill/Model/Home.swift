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
    
    func calcCurrentlyUsedWatt() -> Double {
        var runningWatt: Double = 0.0
        for acc in devices{
            if acc.isActive == true { runningWatt += Double(acc.VARating!) * 0.8}
        }
        return runningWatt
    }
    
    func calculateTotalKwH(month: Date) -> Double {
        devices.reduce(0.0) { total, accessory in
            
            let hoursUsed = accessory.getTotalDuration(month: Date(), unit: .hr)
            let kilowatts = Double(accessory.VARating!) * 0.8 / 1000.0
            
            return total + (hoursUsed * kilowatts)
        }
    }
    
    func getMonthlySummary() -> monthlyUsageSummary {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        let currentKwh = calculateTotalKwH(month: now)
        let previousKwh = calculateTotalKwH(month: lastMonth)

        return monthlyUsageSummary(
            currentmonthkwh: currentKwh,
            previousmonthkwh: previousKwh,
            currentmonthSpend: currentKwh * priceperKwh!,
            previousmonthSpend: previousKwh * priceperKwh!
        )
    }
    
}



