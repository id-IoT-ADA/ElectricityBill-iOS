//
//  MonitorView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 01/07/26.
//

import SwiftUI
import HomeKit
import SwiftData

struct MonitoringView: View {
    @EnvironmentObject private var homeStore: HomeStore
    @Environment(\.modelContext) private var context
    @State private var showAddDevice = false

    var body: some View {
        NavigationStack {
            List(homeStore.pairedAccessories, id: \.uniqueIdentifier)  { accessory in
                NavigationLink {
                    DeviceEnergyView(accessory: accessory, context: context)   // oper context
                        .navigationTitle(accessory.name)
                } label: {
                    Text(accessory.name)
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                Image("OnBoarding Background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
            .navigationTitle("Monitoring")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddDevice = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDevice) {
                AddDeviceView()
            }
        }
    }
}

struct DeviceListRow : View {
    @Binding var isActive : Bool
    
    var body: some View {
        HStack {
            Image("MoneyBag")
            VStack(alignment: .leading) {
                Text("Electricity Bill")
                    .font(.title)
                    .bold()
                Text("25 kWh")
                    .font(.title2)
            }
            .padding(.leading, 10)
            Toggle(isOn: $isActive) {
                
            }
        }
    }
}

#Preview {
    MonitoringView()
}
