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
    var category: String
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
        category: String,
        VARating: Int? = 0,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        home: Home? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.VARating = VARating
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.home = home
    }
    
    func getTotalDuration(month: Int?, unit: Unit) -> Double{
        
        let divider = unit == .hr ? 3600.0 : 60.0
        var totalDuration: Double {
            var totalDur = usageRecords.reduce(0) { total, record in
                guard month != nil, record.month == month, let endTime = record.endTime else { return total }
                return total + (endTime.timeIntervalSince(record.startTime) / divider)
            }
            
            if isActive,
               let currentUsage = usageRecords.last(where: { $0.endTime == nil }){
                
                totalDur += Date.now.timeIntervalSince(currentUsage.startTime) / divider
            }
            
            return totalDur
        }
        
        return totalDuration
    }
}

enum Unit: String{
    case m
    case hr
}
