//
//  DeviceScanListView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 02/07/26.
//

import SwiftUI
import CoreBluetooth

struct DeviceScanListView: View {
    @ObservedObject var ble: BLEProvisioningManager
    let onSelect: (CBPeripheral) -> Void

    var body: some View {
        VStack {
            if ble.status == .scanning {
                HStack {
                    ProgressView()
                    Text("Searching for devices...")
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
            }

            if ble.discoveredDevices.isEmpty && ble.status == .scanning {
                Spacer()
                Text("Make sure your device is powered on and in setup mode.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                List(ble.discoveredDevices, id: \.identifier) { peripheral in
                    Button {
                        onSelect(peripheral)
                    } label: {
                        HStack {
                            Image(systemName: "wave.3.right.circle.fill")
                                .foregroundStyle(.blue)
                            Text(peripheral.name ?? "Unknown Device")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }

            Button(ble.status == .scanning ? "Stop Scanning" : "Scan Again") {
                ble.status == .scanning ? ble.stopScan() : ble.startScan()
            }
            .padding(.bottom)
        }
    }
}

// Needed for .sheet(item:) to work with CBPeripheral
extension CBPeripheral: Identifiable {
    public var id: UUID { identifier }
}
