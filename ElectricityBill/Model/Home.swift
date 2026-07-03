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
    var id: UUID = UUID()
    var kwHlimit: Int?
    var homeName: String
    
    init(kwHlimit: Int = 0, homeName: String) {
        self.kwHlimit = kwHlimit
        self.homeName = homeName
    }
    
}
