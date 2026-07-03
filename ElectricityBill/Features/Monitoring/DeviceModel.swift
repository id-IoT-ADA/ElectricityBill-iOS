//
//  DeviceModel.swift
//  ElectricityBill
//
//  Created by Ikhwan on 01/07/26.
//

import Foundation

struct DeviceModel: Codable {
    let id: Int
    let name: String
    let kWh: Double
    let icon: String
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?
    let deletedAt: Date?
}
