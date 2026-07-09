//
//  DeviceEnergyView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 07/07/26.
//

import SwiftUI
import SwiftData
import HomeKit

struct DeviceEnergyView: View {
    @StateObject private var monitor: EnergyMonitor
    /// Sumber tampilan on/off yang sama dengan list, supaya kedua layar sinkron.
    let device: DeviceModel
    @Query(sort: \EnergyReading.timestamp, order: .reverse) private var energyReadings: [EnergyReading]

    init(accessory: HMAccessory, device: DeviceModel, context: ModelContext) {
        self.device = device
        _monitor = StateObject(wrappedValue: .init(accessory: accessory, context: context))
    }

    var body: some View {
        VStack(spacing: 16) {
            // Daya sesaat, ditonjolkan. Ditampilkan dalam mW agar beban kecil
            // (mis. LED bench) tetap terbaca — 0.4 mW, bukan "0.0 W".
            VStack(spacing: 2) {
                Text(String(format: "%.3f", monitor.watt * 1000))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("mW").font(.headline).foregroundStyle(.secondary)
            }
            .padding(.top)

            // Lamp control — drives the ESP32 relay via the Outlet's On characteristic.
            // Baca `device.isActive` (sumber yang sama dengan list) agar tetap sinkron;
            // set memperbarui state app + usage record DAN menulis ke relay HomeKit.
            Toggle(isOn: Binding(
                get: { device.isActive },
                set: { newValue in
                    device.setActive(newValue)
                    monitor.setOn(newValue)
                }
            )) {
                Label("Lamp", systemImage: "lightbulb.fill")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            // Semua metrik live — cermin dari baris Serial log firmware:
            // V | I(mA) | P(mW) | E(Wh) | E(kWh)
            VStack(spacing: 10) {
                metricRow("Voltage", monitor.voltage,        unit: "V",   spec: "%.3f", icon: "bolt.fill")
                metricRow("Current", monitor.current * 1000, unit: "mA",  spec: "%.2f", icon: "wave.3.right")
                metricRow("Power",   monitor.watt * 1000,    unit: "mW",  spec: "%.3f", icon: "gauge.with.dots.needle.67percent")
                metricRow("Energy",  monitor.kWh * 1000,     unit: "Wh",  spec: "%.6f", icon: "leaf.fill")
                metricRow("Total",   monitor.kWh,            unit: "kWh", spec: "%.9f", icon: "sum")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Divider()

            Text("History")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            List(energyReadings) { r in
                HStack {
                    Text(r.timestamp, format: .dateTime.hour().minute().second())
                    Spacer()
                    Text(String(format: "%.3f mW", r.watt * 1000))
                    Text(String(format: "%.6f Wh", r.kWh * 1000))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .monospacedDigit()
            }
            .listStyle(.plain)
        }
        .padding()
    }

    /// Satu baris metrik: nama + nilai berformat + satuan.
    @ViewBuilder
    private func metricRow(_ name: String, _ value: Double, unit: String, spec: String, icon: String) -> some View {
        HStack {
            Label(name, systemImage: icon)
            Spacer()
            Text("\(String(format: spec, value)) \(unit)")
                .monospacedDigit()
                .bold()
        }
        .font(.subheadline)
    }
}
