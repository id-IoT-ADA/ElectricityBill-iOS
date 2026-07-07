//
//  DeviceModel.swift
//  ElectricityBill
//
//  Created by Ikhwan on 01/07/26.
//

import Foundation
import SwiftData

@Model
class DeviceModel {
    var id: UUID
    var name: String
    var icon: String
    var VARating: Int?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date?
    var deletedAt: Date?
    
    var home: Home?
    
    @Relationship(deleteRule: .cascade, inverse: \DeviceUsageRecord.device)
    var usageRecords: [DeviceUsageRecord] = []
    
    init(
        id: UUID,
        name: String,
        icon: String,
        VARating: Int? = nil,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        home: Home? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.VARating = VARating
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.home = home
    }
    
    var totalDurationMinutes: Int {
        usageRecords.reduce(0) { $0 + $1.durationMinutes }
    }
}
