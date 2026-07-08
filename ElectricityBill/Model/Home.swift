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
    
}



