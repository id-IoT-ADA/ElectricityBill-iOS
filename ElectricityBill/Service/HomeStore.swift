//
//  HomeStore.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 28/06/26.
//

import HomeKit
import Combine

class HomeStore: NSObject, ObservableObject, HMHomeManagerDelegate{
    private var homeManager = HMHomeManager()
    @Published var homes: [HMHome] = []
    
    override init() {
        super.init()
        self.homeManager.delegate = self
    }

    // Delegate method called when the homes are updated
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        DispatchQueue.main.async{
            self.homes = manager.homes
        }
    }
}
