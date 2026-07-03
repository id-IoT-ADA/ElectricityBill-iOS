//
//  ContentView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 25/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var statusMessage = "Not Connected"
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill"){
                MainPageView()
            }
            Tab("Monitor", systemImage: "inset.filled.rectangle.and.person.filled") {
                MonitoringView()
            }
            Tab("History", systemImage: "triangle") {
                EmptyView()
            }
        }.foregroundStyle(Color(.white))
        
    }
}

#Preview {
    ContentView()
}
