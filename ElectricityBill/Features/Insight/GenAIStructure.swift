//
//  Untitled.swift
//  ElectricityBill
//
//  Created by Keira on 02/07/26.
//

import FoundationModels

@Generable
struct EnergyInsightCard {
    @Guide(description: "An encouraging title under 5 words focusing on saving energy.")
    var title: String
    
    @Guide(description: "A friendly overview under 20 words highlighting percentage drop and savings in Rupiah (Rp).")
    var bodyMessage: String
}

struct InsightPrompts{
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
}




