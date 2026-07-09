//
//  Functions.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 09/07/26.
//
import Foundation

func formatToIDR(amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "id_ID")
    formatter.currencySymbol = "Rp "
    
    
    if let finalString = formatter.string(from: NSNumber(value: amount)){
        return finalString
    }
    else{
        return "Rp "
    }
}

let sectionOrder: [String] = ["Lamp", "AC", "Television", "Others"]

let logoNames = [
    "Lamp" : "lightbulb.min",
    "AC" : "air.conditioner.horizontal",
    "Television" : "tv",
    "Others" : "macbook.and.iphone"
]
