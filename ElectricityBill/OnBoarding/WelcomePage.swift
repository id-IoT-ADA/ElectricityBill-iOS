//
//  Untitled.swift
//  ElectricityBill
//
//  Created by Keira on 29/06/26.
//

import SwiftUI

struct WelcomePage: View {
    
    var body: some View {
        
        ZStack{
            Image("OnBoarding Background")
                .ignoresSafeArea()
            
            VStack (alignment: .center, spacing: 28){
                Text("Welcome to Savergy!")
                    .font(.title2)
                    .bold()
                Text("Savergy helps you monitor, control, and save on your home electricity, all from your phone.")
                    .lineLimit(3)
                    .multilineTextAlignment(.center)

            }
            .padding(EdgeInsets(top: 41, leading: 30, bottom: 38, trailing: 25))
            .frame(width: 359, height: 220, alignment: .center)
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 34))
            
        }
    }
    
}

#Preview {
    WelcomePage()
}
