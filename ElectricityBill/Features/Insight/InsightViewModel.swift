//
//  InsightViewModel.swift
//  ElectricityBill
//
//  Created by Keira on 02/07/26.
//

import Combine
import Foundation

struct InsightPage: Identifiable {
    let id: Int
    var card: EnergyInsightCard?
}

@MainActor
final class InsightViewModel: ObservableObject {
    @Published private(set) var pages: [InsightPage] = [
        InsightPage(id: 0, card: nil),
        InsightPage(id: 1, card: nil)
    ]
    @Published private(set) var isLoading = false

    let weeklySummary = MockEnergyData.weeklySummary
    let mostUsedDevices = MockEnergyData.mostUsedDevices

    private let generator = EnergyInsightGenerator()
    private var didLoad = false

    func loadInsightsIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        isLoading = true
        defer { isLoading = false }

        async let usageCard = resolveCard(
            prompt: InsightPrompts.buildPromptForSavings(
                percent: Int(weeklySummary.percentChange.rounded()),
                rupiahSaved: weeklySummary.estimatedRupiahSaved
            ),
            fallback: Self.fallbackUsageCard(summary: weeklySummary)
        )

        async let recommendationCard = resolveCard(
            prompt: InsightPrompts.buildPromptForRecommendation(
                deviceName: mostUsedDevices.first?.name ?? "your most used device",
                hours: Double(mostUsedDevices.first?.durationMinutes ?? 0) / 60.0
            ),
            fallback: Self.fallbackRecommendationCard(device: mostUsedDevices.first)
        )

        pages = [
            InsightPage(id: 0, card: await usageCard),
            InsightPage(id: 1, card: await recommendationCard)
        ]
    }

    private func resolveCard(prompt: String, fallback: EnergyInsightCard) async -> EnergyInsightCard {
        (try? await generator.generateCard(prompt: prompt)) ?? fallback
    }

    private static func fallbackUsageCard(summary: WeeklyUsageSummary) -> EnergyInsightCard {
        let percent = Int(summary.percentChange.rounded())
        if percent >= 0 {
            return EnergyInsightCard(
                title: "Lower Energy Usage This Week",
                bodyMessage: "Your electricity consumption dropped by \(percent)% compared to last week, saving you an estimated Rp\(summary.estimatedRupiahSaved.thousandsGrouped)!"
            )
        } else {
            return EnergyInsightCard(
                title: "Higher Energy Usage This Week",
                bodyMessage: "Your electricity consumption rose by \(abs(percent))% compared to last week, costing you an estimated Rp\(summary.estimatedRupiahSaved.thousandsGrouped) more."
            )
        }
    }

    private static func fallbackRecommendationCard(device: DeviceUsage?) -> EnergyInsightCard {
        guard let device else {
            return EnergyInsightCard(title: "Stay Efficient", bodyMessage: "Keep an eye on your most active devices to save more energy.")
        }
        return EnergyInsightCard(
            title: "Save More Energy",
            bodyMessage: "\(device.name) ran for \(device.formattedDuration) this week. Try turning it off when the room is empty to cut costs further."
        )
    }
}
