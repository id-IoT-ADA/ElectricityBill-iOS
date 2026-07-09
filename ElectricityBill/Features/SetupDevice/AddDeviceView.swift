//
//  AddDeviceView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 02/07/26.
//

import SwiftUI
import CoreBluetooth

struct AddDeviceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ble = BLEProvisioningManager()
    @State private var provisioningPeripheral: CBPeripheral?
    @State private var showAddAccessory = false

    var body: some View {
        VStack {
            switch ble.status {
            case .initializing:
                ProgressView("Checking Bluetooth...")

            case .bluetoothOff:
                statusMessage(
                    icon: "antenna.radiowaves.left.and.right.slash",
                    title: "Bluetooth is Off",
                    message: "Turn on Bluetooth to find nearby devices."
                )

            case .permissionDenied:
                VStack(spacing: 16) {
                    statusMessage(
                        icon: "lock.fill",
                        title: "Bluetooth Access Needed",
                        message: "Allow Bluetooth access in Settings to set up your device."
                    )
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .unsupported:
                statusMessage(
                    icon: "exclamationmark.triangle",
                    title: "Not Supported",
                    message: "This device doesn't support Bluetooth LE."
                )

            // The scan list stays mounted while provisioning so the sheet
            // (owned by AddDeviceView below) is never torn down mid-connect.
            default:
                DeviceScanListView(ble: ble) { peripheral in
                    provisioningPeripheral = peripheral
                    ble.connect(to: peripheral)
                }
            }
        }
        .padding()
        .onAppear {
            if ble.status == .ready { ble.startScan() }
        }
        .sheet(item: $provisioningPeripheral, onDismiss: {
            if ble.status == .success {
                // Wi-Fi is provisioned — move straight to HomeKit pairing,
                // don't drop back into BLE scanning.
                ble.reset()          // release BLE; the ESP32 restarts and drops the link anyway
                // Defer so we don't present the cover while the sheet is still dismissing.
                DispatchQueue.main.async { showAddAccessory = true }
            } else {
                ble.reset()
                if ble.status == .ready { ble.startScan() }
            }
        }) { peripheral in
            WiFiCredentialsSheet(ble: ble, deviceName: peripheral.name ?? "Device")
        }
        .fullScreenCover(isPresented: $showAddAccessory, onDismiss: {
            // Provisioning + HomeKit pairing selesai — tutup seluruh flow setup
            // dan kembali ke MonitoringView. JANGAN restart BLE scan, karena itu
            // yang bikin sheet seolah "kebuka lagi" untuk scanning ulang.
            dismiss()
        }) {
            AddAccessoryFlow { showAddAccessory = false }
        }
    }

    @ViewBuilder
    private func statusMessage(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
