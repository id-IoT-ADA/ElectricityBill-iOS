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

    @Guide(description: "A friendly overview under 20 words highlighting percentage drop and rupiah differences in Rupiah (Rp).")
    var bodyMessage: String
}

enum InsightPrompts {
    static func buildPromptForSavings(percent: Int, rupiahdiff: Int) -> String {
        let isIncrease = percent < 0
        let direction = isIncrease ? "increase" : "decrease"
        let absPercent = abs(percent)
        let absRupiah = abs(rupiahdiff)

        return """
            Generate an energy insight card text based strictly on the facts below.

            Facts (already determined — do not reinterpret, recalculate, or contradict these):
            - Usage direction this month vs. last month: \(direction)
            - Percent change: \(absPercent)%
            - Rupiah difference: Rp\(absRupiah)

            Rules:
            - Do not calculate or invent any new metrics.
            - Describe the change using the word "\(direction)" (or a natural synonym like "up"/"down") — never state the opposite direction.
            - Always present both numbers as positive; never show a minus sign.
            - If direction is "increase", the tone should gently warn the user to watch their usage.
            - If direction is "decrease", the tone should be congratulatory about the savings.
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
