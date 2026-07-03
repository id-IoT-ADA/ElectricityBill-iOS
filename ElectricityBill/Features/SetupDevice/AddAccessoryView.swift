//
//  AddAccessoryView.swift
//  ElectricityBill
//
//  In-app HomeKit "Add Accessory" flow — discover, pair, and control the
//  ESP32 (HomeSpan) accessory without leaving the app for Apple's Home app.
//

import SwiftUI
import HomeKit

/// Self-contained HomeKit pairing step used right after Wi-Fi provisioning.
/// Owns its own HomeStore so the HomeKit permission prompt only appears when
/// the user actually reaches this stage (not during BLE scanning).
struct AddAccessoryFlow: View {
    @StateObject private var homeStore = HomeStore()
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            AddAccessoryView(homeStore: homeStore)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: onDone)
                    }
                }
        }
        .onAppear {
            // Arriving straight from Wi-Fi provisioning: begin looking for the
            // freshly-rebooted accessory right away. It becomes discoverable once
            // the ESP32 finishes rebooting into HomeSpan mode (a few seconds).
            homeStore.ensurePrimaryHome()
            homeStore.startSearch()
        }
    }
}

struct AddAccessoryView: View {
    @ObservedObject var homeStore: HomeStore

    var body: some View {
        List {
            if let message = homeStore.statusMessage {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Home") {
                if let home = homeStore.primaryHome {
                    Label(home.name, systemImage: "house.fill")
                } else {
                    Button("Create a Home") { homeStore.ensurePrimaryHome() }
                }
            }

            Section("Add New Device") {
                if homeStore.isSearching {
                    HStack {
                        ProgressView()
                        Text("Searching for devices…")
                            .foregroundStyle(.secondary)
                    }

                    if homeStore.foundAccessories.isEmpty {
                        Text("Make sure the device is powered on and joined to the same Wi-Fi network as this phone.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(homeStore.foundAccessories, id: \.uniqueIdentifier) { accessory in
                        HStack {
                            Image(systemName: "sensor.fill").foregroundStyle(.blue)
                            Text(accessory.name)
                            Spacer()
                            Button("Add") { homeStore.add(accessory) }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                        }
                    }

                    Button("Stop Searching", role: .cancel) { homeStore.stopSearch() }
                } else {
                    Button {
                        homeStore.startSearch()
                    } label: {
                        Label("Search for Devices", systemImage: "plus.circle.fill")
                    }
                }

                Text("When iOS asks for a setup code, enter **1122-3344**.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("My Devices") {
                if homeStore.pairedAccessories.isEmpty {
                    Text("No devices added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(homeStore.pairedAccessories, id: \.uniqueIdentifier) { accessory in
                        accessoryRow(accessory)
                    }
                }
            }
        }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { homeStore.ensurePrimaryHome() }
        .onDisappear { homeStore.stopSearch() }
    }

    @ViewBuilder
    private func accessoryRow(_ accessory: HMAccessory) -> some View {
        if homeStore.powerCharacteristic(for: accessory) != nil {
            Toggle(isOn: Binding(
                get: { homeStore.isOn(accessory) },
                set: { homeStore.setPower($0, for: accessory) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(accessory.name)
                    if !accessory.isReachable {
                        Text("Unreachable")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(!accessory.isReachable)
        } else {
            Text(accessory.name)
        }
    }
}
