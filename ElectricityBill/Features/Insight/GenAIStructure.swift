//
//  GenAIStructure.swift
//  ElectricityBill
//
//  Created by Keira on 02/07/26.
//

import Foundation
import FoundationModels

@Generable
struct EnergyInsightCard {
    @Guide(description: "An encouraging title under 5 words focusing on saving energy.")
    var title: String

    @Guide(description: "A friendly overview under 20 words highlighting percentage drop and savings in Rupiah (Rp).")
    var bodyMessage: String
}

enum InsightPrompts {
    static func buildPromptForSavings(percent: Int, rupiahSaved: Int) -> String {
        return """
            Generate an energy insight card text based strictly on the provided user values.

            Rules:
            - Do not calculate or invent any new metrics.
            - Treat negative percentages as spikes and positive as drops.

            Metrics:
            - Percent Energy Variation: \(percent)% drop
            - Saved Money Amount: Rp\(rupiahSaved)
            """
    }

    static func buildPromptForRecommendation(deviceName: String, hours: Double) -> String {
        return """
            Generate an energy-saving recommendation card based strictly on the provided device usage.

            Rules:
            - Do not calculate or invent any new metrics.
            - Suggest one concrete, actionable habit to reduce usage of this specific device.

            Metrics:
            - Most Used Device: \(deviceName)
            - Hours Active This Week: \(String(format: "%.1f", hours))
            """
    }
}

@MainActor
final class EnergyInsightGenerator {
    enum GeneratorError: Error {
        case unavailable
    }

    func generateCard(prompt: String) async throws -> EnergyInsightCard {
        guard case .available = SystemLanguageModel.default.availability else {
            throw GeneratorError.unavailable
        }

        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt, generating: EnergyInsightCard.self)
        return response.content
    }
}
