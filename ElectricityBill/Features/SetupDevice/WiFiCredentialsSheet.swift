//
//  WiFiCredentialsSheet.swift
//  ElectricityBill
//
//  Created by Ikhwan on 02/07/26.
//

import SwiftUI

struct WiFiCredentialsSheet: View {
    @ObservedObject var ble: BLEProvisioningManager
    let deviceName: String

    @State private var selectedSSID: String = ""
    @State private var manualSSID: String = ""
    @State private var password: String = ""
    @State private var enterManually = false
    @Environment(\.dismiss) private var dismiss

    // The SSID we'll actually send.
    private var effectiveSSID: String {
        enterManually ? manualSSID : selectedSSID
    }

    // Open networks (from the scan) don't require a password. Manual entry always allows one.
    private var passwordRequired: Bool {
        guard !enterManually,
              let network = ble.availableNetworks.first(where: { $0.ssid == selectedSSID })
        else { return true }
        return network.secure
    }

    // Characteristics are ready once connected; allow retry after a failed attempt.
    private var canSend: Bool {
        ble.status == .connected || ble.status == .failed
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Connect \(deviceName) to Wi-Fi") {
                    if enterManually {
                        TextField("Network Name (SSID)", text: $manualSSID)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button("Choose from scanned networks") { enterManually = false }
                            .font(.footnote)
                    } else if ble.status == .connecting || (ble.status == .connected && !ble.networksLoaded) {
                        HStack {
                            ProgressView()
                            Text(ble.status == .connecting ? "Connecting to device..." : "Scanning networks...")
                                .foregroundStyle(.secondary)
                        }
                        if ble.status == .connected {
                            Button("Enter network manually") {
                                enterManually = true
                                manualSSID = ""
                            }
                            .font(.footnote)
                        }
                    } else if ble.networksLoaded && ble.availableNetworks.isEmpty {
                        Text("No networks found nearby.")
                            .foregroundStyle(.secondary)
                        Button("Enter network manually") {
                            enterManually = true
                            manualSSID = ""
                        }
                        .font(.footnote)
                    } else {
                        Picker("Network", selection: $selectedSSID) {
                            Text("Select a network").tag("")
                            ForEach(ble.availableNetworks) { network in
                                networkRow(network).tag(network.ssid)
                            }
                        }
                        Button("Other network…") {
                            enterManually = true
                            manualSSID = ""
                        }
                        .font(.footnote)
                    }

                    SecureField("Password", text: $password)
                }

                statusRow

                Button("Connect") {
                    ble.sendCredentials(ssid: effectiveSSID, password: password)
                }
                .disabled(effectiveSSID.isEmpty || (passwordRequired && password.isEmpty) || !canSend)
            }
            .navigationTitle("Wi-Fi Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        ble.refreshNetworks()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(ble.status != .connected || enterManually)
                }
            }
            .onChange(of: ble.status) { _, newStatus in
                if newStatus == .success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func networkRow(_ network: WiFiNetwork) -> some View {
        HStack {
            Text(network.ssid)
            Spacer()
            if network.secure {
                Image(systemName: "lock.fill").foregroundStyle(.secondary)
            }
            Image(systemName: "wifi", variableValue: signalStrength(for: network.rssi))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        switch ble.status {
        case .sending:
            HStack {
                ProgressView()
                Text("Sending credentials...")
            }
        case .success:
            Label("Connected!", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Label("Connection failed. Check your password and try again.", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        default:
            EmptyView()
        }
    }

    // Map RSSI (~ -90 weak … -40 strong) to the SF Symbol variable-value fill 0…1.
    private func signalStrength(for rssi: Int) -> Double {
        let clamped = Double(min(-40, max(-90, rssi)))
        return (clamped + 90) / 50
    }
}
