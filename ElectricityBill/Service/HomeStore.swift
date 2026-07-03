//
//  HomeStore.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 28/06/26.
//

import HomeKit
import Combine

class HomeStore: NSObject, ObservableObject, HMHomeManagerDelegate {
    private var homeManager: HMHomeManager?
    
    // 1. Give homes a default empty array value
    @Published var homes: [HMHome] = []
    // 2. Add a loading flag so the view waits for the delegate
    @Published var isLoading = true
    
    override init() {
        super.init()
        // 3. Initialize after super.init and set delegate
        self.homeManager = HMHomeManager()
        self.homeManager?.delegate = self
    }

    // Delegate method called when the homes are successfully fetched
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        DispatchQueue.main.async {
            self.homes = manager.homes
            self.isLoading = false // 4. Turn off loading when data arrives
        }
    }
}
