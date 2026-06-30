//
//  MQTTView.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 30/06/26.
//
import SwiftUI

struct MQTTView: View {
    @StateObject private var mqttManager = MQTTManager()
    var body: some View {
        VStack(spacing: 20) {
            Button("Connect to Broker") {
                mqttManager.connect()
            }
            .buttonStyle(.borderedProminent)
            .disabled(mqttManager.connectionStatus == "Connected" ? true : false)
            Text(mqttManager.connectionStatus)
            Button("Send 'Hello'") {
                mqttManager.publish(message: "Hello World", to: "home/livingroom/temperature")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    MQTTView()
}
