//
//  EnergyDataModels.swift
//  ElectricityBill
//
//  Created by Keira on 02/07/26.
//

import Foundation

struct WeeklyUsageSummary {
    let currentWeekKwh: Double
    let previousWeekKwh: Double
    let estimatedRupiahSaved: Int

    var percentChange: Double {
        guard previousWeekKwh > 0 else { return 0 }
        return ((previousWeekKwh - currentWeekKwh) / previousWeekKwh) * 100
    }
}

struct DeviceUsage: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let durationMinutes: Int

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

extension Int {
    var thousandsGrouped: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

enum MockEnergyData {
    static let weeklySummary = WeeklyUsageSummary(
        currentWeekKwh: 86,
        previousWeekKwh: 100,
        estimatedRupiahSaved: 50000
    )

    static let mostUsedDevices: [DeviceUsage] = [
        DeviceUsage(name: "AC Kamar Keira", icon: "wind", durationMinutes: 322),
        DeviceUsage(name: "Lampu Kamar Tidur Karen", icon: "lightbulb.fill", durationMinutes: 279),
        DeviceUsage(name: "AC Kamar Ikhwan", icon: "wind", durationMinutes: 82)
    ]
}
