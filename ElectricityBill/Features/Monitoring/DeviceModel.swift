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
    var usageRecords = [DeviceUsageRecord]()
    
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
//            month: monthDate,
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
        getTotalDuration(month: nil, unit: .hr)
    }
    
    func getTotalDuration(month: Date?, unit: Unit) -> Double{
        
        let divider = unit == .hr ? 3600.0 : 60.0
        var totalDuration: Double {
            var totalDur = usageRecords.reduce(0) { total, record in
                guard month != nil, Calendar.current.component(.month, from: record.startTime) == Calendar.current.component(.month, from: month!), Calendar.current.component(.year, from: record.startTime) == Calendar.current.component(.year, from: month!), let endTime = record.endTime else { return total }
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
    
    func getTotalWattDevice(month: Date) -> Int{
        return Int(Double(VARating!) * 0.8 * getTotalDuration(month: month, unit: .hr))
    }
    
    func getTotalSpendDevice(month: Date, home: Home) -> Double{
        return Double(getTotalWattDevice(month: month)/1000) * home.priceperKwh!
    }
    
    
}

enum Unit: String{
    case m
    case hr
}
