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
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(homeStore).environmentObject(appState)
        }.modelContainer(for: Home.self)
            ContentView().environmentObject(homeStore)
        }.modelContainer(for: [Home.self, EnergyReading.self])
    }
}
