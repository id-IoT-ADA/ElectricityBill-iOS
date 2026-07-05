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
    var kwHlimit: Int?
    var VACapacity: Int?
    var homeName: String
    
    init(id : UUID, kwHlimit: Int = 0, VACapacity: Int = 0, homeName: String) {
        self.id = id
        self.VACapacity = nil
        self.kwHlimit = kwHlimit
        self.homeName = homeName
    }
    
}

