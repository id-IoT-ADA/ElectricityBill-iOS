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
    var usageRecords = [DeviceUsageRecord]()
    
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

}

extension DeviceModel{
    
    //automatically made usage record based on setActive (use this function for toggle)
    func setActive(_ active: Bool, at date: Date = .now, calendar: Calendar = .current) {
        guard active != isActive else { return } // hindari duplikasi kalau state tidak berubah
        
        isActive = active
        
        if active {
            startUsageSession(at: date, calendar: calendar)
        } else {
            endUsageSession(at: date)
        }
    }
    
    //make new usage record everytime a device is turned on
    private func startUsageSession(at date: Date, calendar: Calendar) {
        if let dangling = usageRecords.first(where: { $0.endTime == nil }) {
            closeSession(dangling, at: date)
        }
        
        let monthDate = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? date
        
        let newRecord = DeviceUsageRecord(
            month: monthDate,
            startTime: date,
            endTime: nil,
            kWh: 0,
            device: self
        )
        
        usageRecords.append(newRecord)
    }
    
    //closing session when setActive = false
    private func endUsageSession(at date: Date) {
        guard let openRecord = usageRecords.first(where: { $0.endTime == nil }) else {
            return // tidak ada session yang sedang berjalan, tidak ada yang perlu ditutup
        }
        closeSession(openRecord, at: date)
    }
    
    private func closeSession(_ record: DeviceUsageRecord, at date: Date) {
        record.endTime = date
//        record.kWh = estimatedKWh(durationInMinutes: record.durationInMinutes)
    }
}
