//
//  OnBoardingPage.swift
//  ElectricityBill
//
//  Created by Keira on 01/07/26.
//

import SwiftUI

struct OnBoardingPage: View {
    @State private var currentPage = 0
    
    init(){
        UIPageControl.appearance().currentPageIndicatorTintColor = .white
        UIPageControl.appearance().pageIndicatorTintColor = .systemGray4
    }
    
    var body: some View {
        ZStack{
            Image("OnBoarding Background")
                .ignoresSafeArea()
            
            VStack{
                TabView(selection: $currentPage) {
                    
                    // First Page: Welcome
                    WelcomePage()
                        .tag(0)
                    
                    // Second Page: Select Electricity
                    SelectElectricity()
                        .tag(1)
                    
                }
                // Forces the TabView to behave like a swipeable onboarding carousel
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 550)
            }
        }
    }
}

struct WelcomePage: View {
    
    var body: some View {
        
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

struct SelectElectricity: View {
    
    let Ecapacity = ["450 VA","900 VA (Subsidi)","900 VA(Non-subsidi)","1300 - 2200 VA", ">3500 VA"  ]
    
    @State private var selection: String? = nil
    @State private var isExpanded = false
    
    var body: some View {

        VStack{
            Text("Select Electricity Capacity")
                .font(.title3)
                .bold()
            
            Button(action: {
                withAnimation { isExpanded.toggle() }
            }) {
                HStack {
                    Text(selection ?? "Electricity Capacity")
                        .foregroundColor(selection == nil ? .secondary : .primary)
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.right" : "chevron.right")
                        .foregroundColor(.white)
                    
                }
                .padding()
                .glassEffect(.clear)
                .cornerRadius(10)
            }
            .padding(.horizontal,20)
            
            if isExpanded {
                List(Ecapacity, id: \.self) { item in
                    Button(action: {
                        withAnimation {
                            selection = item
                            isExpanded = false
                        }
                    }) {
                        HStack {
                            Text(item)
                                .foregroundColor(.primary)
                            Spacer()
                            if selection == item {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
                    .listRowSeparatorTint(Color.white.opacity(0.12))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .frame(maxHeight: 290)
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
        }
    }
}


#Preview {
    OnBoardingPage()
}
