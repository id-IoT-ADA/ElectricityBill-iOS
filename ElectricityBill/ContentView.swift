//
//  ContentView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 25/06/26.
//

import SwiftUI
import SwiftData
import HomeKit

struct ContentView: View {
//    @State private var statusMessage = "Not Connected"
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var homeStore: HomeStore
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill"){
                MainPageView()
            }
            Tab("Monitor", systemImage: "inset.filled.rectangle.and.person.filled") {
                EmptyView()
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
