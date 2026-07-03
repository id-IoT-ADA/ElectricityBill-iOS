//
//  HomeStore.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 28/06/26.
//

import HomeKit
import Combine
import SwiftUI

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
    
    func createHome(homeName: String) -> [String]{
        var errMsg = ["", ""]
        homeManager.addHome(withName: homeName){ [weak self] (newHome, error) in
            
            if let error = error {
                errMsg = ["err", error.localizedDescription]
                return
            }
            if let newHome = newHome {
                errMsg = ["success", "Successfully added home: \(newHome.name)"]
            }
        }
        
        return errMsg
    }
}
