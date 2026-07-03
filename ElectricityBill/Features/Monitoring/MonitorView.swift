//
//  MonitorView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 01/07/26.
//

import SwiftUI

struct MonitoringView: View {
    @State var isActive: Bool = false
    @State private var showAddDevice = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("OnBoarding Background")
                    .ignoresSafeArea()

                DeviceListRow(isActive: $isActive)
            }
            .navigationTitle("Devices")
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
