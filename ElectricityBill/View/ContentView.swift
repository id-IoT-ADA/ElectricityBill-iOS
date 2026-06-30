//
//  ContentView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 25/06/26.
//

import SwiftUI

struct ContentView: View {
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
