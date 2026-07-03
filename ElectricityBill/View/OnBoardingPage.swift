//
//  OnBoardingPage.swift
//  ElectricityBill
//
//  Created by Keira on 01/07/26.
//

import SwiftUI
import HomeKit

struct OnBoardingPage: View {
    @State private var currentPage = 0
    @State var selection: String? = nil
    @State var inputLimit: Int? = nil
    @State var isExpanded: Bool = false
    
    init(){
        UIPageControl.appearance().currentPageIndicatorTintColor = .white
        UIPageControl.appearance().pageIndicatorTintColor = .systemGray4
    }
    
    var isSelectionValid: Bool {
        if selection == "Others" {
            return inputLimit != nil && inputLimit! > 0
        }
        return selection != nil
    }
    
    var body: some View {
        NavigationStack{
            ZStack{
                Image("OnBoarding Background")
                    .ignoresSafeArea()
                
                VStack{
                    TabView(selection: $currentPage) {
                        
                        getHome()
                            .tag(0)
                        
                        SelectElectricity(isExpanded: $isExpanded, selection: $selection, inputLimit: $inputLimit)
                            .tag(1)
                        
                    }
                    // Forces the TabView to behave like a swipeable onboarding carousel
                    .tabViewStyle(.page(indexDisplayMode: isExpanded ? .never : .always))
                    .frame(height: 300)
                    
                    if !isExpanded {
                        NavigationLink(value: "NextPage") {
                            Text("Done")
                                .foregroundColor(isSelectionValid ? .primary : .secondary)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .opacity(isSelectionValid ? 1.0 : 0.4)
                        }
                        // 3. Keep the disabled modifier directly on the NavigationLink
                        .disabled(!isSelectionValid)
                        .padding()
                    }
                }
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

struct getHome: View {
    @StateObject private var homelist = HomeStore()
    @State var selectedHome: HMHome?
    
    var body: some View {
        NavigationStack {
            Group {
                // 1. Show a loading indicator first while HomeKit communicates with iCloud
                if homelist.isLoading {
                    ProgressView("Connecting to HomeApp...")
                } else if homelist.homes.isEmpty {
                    ContentUnavailableView(
                        "No Homes Found",
                        systemImage: "house",
                        description: Text("Open the Apple Home app to create a configuration.")
                    )
                } else {
                    VStack{
                        Text ("Select a home to start")
                        
                        List(homelist.homes, id: \.uniqueIdentifier) { home in
                            Button(action: {
                                selectedHome = home
                            }) {
                                HStack {
                                    Text(home.name)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    if selectedHome == home {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .foregroundStyle(Color.white)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
                        .listRowSeparatorTint(Color.white.opacity(0.12))
                    }
                }
            }
        }
    }
}



struct SelectElectricity: View {
    
    let Ecapacity: [String] = ["450 VA","900 VA (Subsidi)","900 VA(Non-subsidi)","1300 VA", "2200 VA", "Others"]
    
    
    var VAlimit = [
        "450 VA": 450,
        "900 VA (Subsidi)": 900,
        "900 VA(Non-subsidi)": 900,
        "1300 VA": 1300,
        "2200 VA": 2200,
    ]
    
    @Binding var isExpanded: Bool
    @Binding var selection: String?
    @Binding var inputLimit: Int?
    
    
    var selectedlimit: Int? {
        guard let selection = selection else { return nil }
        return VAlimit[selection]!
    }
    
    var body: some View {
        
        VStack{
            Text("Select Electricity Capacity")
                .font(.title3)
                .bold()
            
            Button(action: {
                withAnimation { isExpanded.toggle() }
            }) {
                HStack {
                    Text(selection ?? "Set")
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
                            selection = item
                            isExpanded = false
                    }) {
                        HStack {
                            Text(item)
                                .foregroundColor(item == "Others" ? .blue : .primary)
                            Spacer()
                            if selection == item {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
                    .listRowSeparatorTint(Color.white.opacity(0.12))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .frame(maxHeight: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
            if selection == "Others"{
                TextField("Input your KwH limit", value: $inputLimit, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .transition(.opacity)
            }
        }
    }
}


#Preview {
    OnBoardingPage()
}
