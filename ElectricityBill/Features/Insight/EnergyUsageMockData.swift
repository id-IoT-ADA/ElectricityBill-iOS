//
//  EnergyDataModels.swift
//  ElectricityBill
//
//  Created by Keira on 02/07/26.
//

import Foundation

enum MockEnergyData {
    static let monthlySummary = monthlyUsageSummary(
        currentmonthkwh: 100,
        previousmonthkwh: 50,
        currentmonthSpend: 500000,
        previousmonthSpend: 100000
    )
}
