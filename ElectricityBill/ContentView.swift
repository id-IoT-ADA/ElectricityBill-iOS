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
        VStack(spacing: 30) {
            Text("ESP32 LED Controller")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Status: \(statusMessage)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Turn ON Button
            Button(action: {
                sendLEDCommand(endpoint: "on")
            }) {
                Text("Turn LED ON")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // Turn OFF Button
            Button(action: {
                sendLEDCommand(endpoint: "off")
            }) {
                Text("Turn LED OFF")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // Function to send HTTP request to ESP32
    func sendLEDCommand(endpoint: String) {
        guard let url = URL(string: "http://192.168.4.1/led/\(endpoint)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.statusMessage = "Error: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.statusMessage = "Successfully turned \(endpoint.uppercased())"
                } else {
                    self.statusMessage = "Failed to reach ESP32"
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
