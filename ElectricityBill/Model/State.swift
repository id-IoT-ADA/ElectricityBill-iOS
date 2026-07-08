//
//  State.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 07/07/26.
//
import SwiftUI
import Combine
import HomeKit

class AppState: ObservableObject {
    @Published var currentHome: Home?
}
