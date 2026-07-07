//
//  ElectricityBillApp.swift
//  ElectricityBill
//
//  Created by Ikhwan on 25/06/26.
//

import SwiftUI
import SwiftData

@main
struct ElectricityBillApp: App {
    @StateObject private var homeStore = HomeStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(homeStore)
        }.modelContainer(for: [Home.self, EnergyReading.self])
    }
}
