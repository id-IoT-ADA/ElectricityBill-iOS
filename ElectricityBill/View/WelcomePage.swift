//
//  WelcomePage.swift
//  ElectricityBill
//
//  Created by Keira on 05/07/26.
//

import SwiftUI

struct WelcomePage: View {
    
    let CardFill = [
        "Monitor" : "Track real-time power consumption and usage of every connected device in your home.",
        "Control": "Turn your home devices on or off remotely and monitor their status from anywhere, anytime.",
        "Insights": "Get AI-powered recommendations, monthly usage trends to help you save energy and reduce your electricity bill."
    ]
    
    let Orderkeys = ["Monitor", "Control", "Insights"]
    
    var CardIcon = ["tv", "switch.2", "lightbulb.max.fill"]
    
    var body: some View {
        NavigationStack{
            ZStack{
                
                Image("OnBoarding Background")
                    .ignoresSafeArea()
                
                VStack(alignment:.center, spacing: 70){
                    HStack{
                        Text("Welcome to ")
                            .font(.title)
                        Text("Savergy")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 34)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 34))
                        
                        VStack(alignment: .leading, spacing: 28) {
                            // 2. Sort the keys to pair them predictably with the icon array indices
                            let combinedData = Array(zip(Orderkeys, CardIcon))
                            
                            ForEach(combinedData, id: \.0) { key, iconName in
                                HStack(alignment: .center, spacing: 16) {
                                    // Left-aligned icon
                                    Image(systemName: iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .padding(.leading, 10)
                                        .padding(.trailing,0)
                                        .foregroundColor(.white)
                                    
                                    // Right side text layout stacked vertically
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(key)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        
                                        // Safely unwrapping the description from the dictionary
                                        Text(CardFill[key] ?? "")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                            .padding(.trailing, 14)
                                            .lineLimit(4)
                                    }
                                    .padding(8)
                                }
                            }
                        }
                        .padding(.trailing, 14)
                        .padding(.leading, 43)
                    }
                    
                    .frame(width: 362, height: 388)
                    
                    NavigationLink(destination: OnBoardingPage()){
                        Text("Continue")
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomePage()
}
