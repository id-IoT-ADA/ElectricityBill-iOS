//
//  AccessoryModel.swift
//  ElectricityBill
//
//  Created by Keira on 06/07/26.
//

import SwiftData
import SwiftUI

class AccessoryModel{
    var id: UUID
    var VADevice: Int?
    var AccessoryName: String
    var HomeName: String
    var DurationperMonth : Int
    var TotalDuration: Int
    
    init(id: UUID, VADevice: Int?, AccessoryName: String, HomeName: String, DurationperMonth: Int, TotalDuration: Int) {
        self.id = id
        self.VADevice = VADevice
        self.AccessoryName = AccessoryName
        self.HomeName = HomeName
        self.DurationperMonth = DurationperMonth
        self.TotalDuration = TotalDuration
    }
    
}

