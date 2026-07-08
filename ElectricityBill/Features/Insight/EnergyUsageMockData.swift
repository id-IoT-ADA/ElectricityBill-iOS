//
//  EnergyUsageMockData.swift
//  ElectricityBill
//
//  Created by Keira on 02/07/26.
//

import Foundation

enum MockEnergyData {
    private static let pricePerKwh: Double = 1444.0
    
    static let devices: [DeviceModel] = {
        let calendar = Calendar.current
        let now = Date()
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? thisMonthStart
        
        func session(in monthStart: Date, day: Int, hour: Int, durationMinutes: Int, kWh: Double) -> DeviceUsageRecord {
            var comps = calendar.dateComponents([.year, .month], from: monthStart)
            comps.day = day
            comps.hour = hour
            let start = calendar.date(from: comps) ?? monthStart
            let end = calendar.date(byAdding: .minute, value: durationMinutes, to: start) ?? start
            return DeviceUsageRecord(startTime: start, endTime: end, kWh: kWh)
        }
        
        let ac1 = DeviceModel(id: UUID(), name: "AC Kamar Keira", category: "AC", VARating: 900)
        let lamp = DeviceModel(id: UUID(), name: "Lampu Kamar Tidur Karen", category: "Lamp", VARating: 15)
        let ac2 = DeviceModel(id: UUID(), name: "AC Kamar Ikhwan", category: "AC", VARating: 900)
        
        let assignments: [(DeviceModel, DeviceUsageRecord)] = [
            // This month
            (ac1, session(in: thisMonthStart, day: 3, hour: 13, durationMinutes: 180, kWh: 2.7)),
            (ac1, session(in: thisMonthStart, day: 12, hour: 20, durationMinutes: 142, kWh: 2.1)),
            (lamp, session(in: thisMonthStart, day: 5, hour: 19, durationMinutes: 180, kWh: 0.045)),
            (lamp, session(in: thisMonthStart, day: 18, hour: 21, durationMinutes: 99, kWh: 0.025)),
            (ac2, session(in: thisMonthStart, day: 9, hour: 14, durationMinutes: 82, kWh: 1.2)),
            // Last month — higher, so this month reads as a drop
            (ac1, session(in: lastMonthStart, day: 4, hour: 13, durationMinutes: 210, kWh: 3.15)),
            (ac1, session(in: lastMonthStart, day: 15, hour: 20, durationMinutes: 200, kWh: 3.0)),
            (lamp, session(in: lastMonthStart, day: 6, hour: 19, durationMinutes: 160, kWh: 0.04)),
            (ac2, session(in: lastMonthStart, day: 10, hour: 14, durationMinutes: 130, kWh: 1.9))
        ]
        
        for (device, record) in assignments {
            record.device = device
            device.usageRecords.append(record)
        }
        
        return [ac1, lamp, ac2]
    }()
    
    static var monthlySummary: monthlyUsageSummary {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        func totalKwh(for month: Date) -> Double {
            devices
                .flatMap(\.usageRecords)
                .filter { calendar.isDate($0.startTime, equalTo: month, toGranularity: .month) }
                .reduce(0) { $0 + $1.kWh! }
        }
        
        let currentKwh = totalKwh(for: now)
        let previousKwh = totalKwh(for: lastMonth)
        
        return monthlyUsageSummary(
            currentmonthkwh: currentKwh,
            previousmonthkwh: previousKwh,
            currentmonthSpend: currentKwh * pricePerKwh,
            previousmonthSpend: previousKwh * pricePerKwh
        )
    }
    
    static var mostUsedDevices: [DeviceModel] {
        let now = Date()
        return devices.sorted { $0.usageRecords.totalDurationMinutes(forMonth: now) > $1.usageRecords.totalDurationMinutes(forMonth: now) }
    }
}
