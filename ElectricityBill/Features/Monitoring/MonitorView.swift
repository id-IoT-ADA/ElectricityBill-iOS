//
//  MonitorView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 01/07/26.
//

import SwiftUI

struct MonitoringView: View {
    @State var isActive: Bool = false
    
    var body: some View {
        ZStack {
            Image("OnBoarding Background")
                .ignoresSafeArea()
            
            DeviceListRow(isActive: $isActive)
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
