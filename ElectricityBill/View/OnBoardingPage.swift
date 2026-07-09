//
//  OnBoardingPage.swift
//  ElectricityBill
//
//  Created by Keira on 01/07/26.
//

import SwiftUI
import HomeKit
import SwiftData

struct OnBoardingPage: View {
    @State private var currentPage = 0
    @State var selection: String? = nil
    @State var inputLimit: Int? = nil
    @State var isExpanded: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var context
    @State private var selectedHome: HMHome?
    @State private var priceperKwH: Double = 0.0
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var homelist : HomeStore
    
    static let priceperKwHDict = [
        "450 VA": 415.0,
        "900 VA (Subsidi)": 605.0,
        "900 VA(Non-subsidi)": 1352.0,
        "1300 VA": 1444.70,
        "2200 VA": 1444.70,
        "Others" : 1699.53
    ]
    
    init(){
        UIPageControl.appearance().currentPageIndicatorTintColor = .white
        UIPageControl.appearance().pageIndicatorTintColor = .systemGray4
    }
    
    var isSelectionValid: Bool {
        guard selectedHome != nil else { return false }
        if selection == "Others" {
            return inputLimit != nil && inputLimit! > 0
        }
        return selection != nil
    }
    
    private var resolvedLimit: Int? {
        if selection == "Others" {
            return inputLimit
        }
        guard let selection else { return nil }
        return SelectElectricity.VAlimit[selection]
    }
    
    
    var body: some View {
        ZStack{
            Image("OnBoarding Background")
                .ignoresSafeArea()
            
            VStack{
                TabView(selection: $currentPage) {
                    
                    getHome(selectedHome: $selectedHome)
                        .tag(0)
                    
                    SelectElectricity(isExpanded: $isExpanded, selection: $selection, inputLimit: $inputLimit)
                        .tag(1)
                    
                }
                // Forces the TabView to behave like a swipeable onboarding carousel
                .tabViewStyle(.page(indexDisplayMode: isExpanded ? .never : .always))
                .frame(height: 300)
                
                if !isExpanded {
                    Button {
                        finishOnboarding()
                    } label: {
                        Text("Done")
                            .foregroundColor(isSelectionValid ? .primary : .secondary)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .opacity(isSelectionValid ? 1.0 : 0.4)
                    }
                    .disabled(!isSelectionValid)
                    .padding()
                }
            }
        }
    }
    private func finishOnboarding() {
        guard let selectedHome, let limit = resolvedLimit else { return }
        priceperKwH = OnBoardingPage.priceperKwHDict[selection!]!
        let homeObj = Home(id: selectedHome.uniqueIdentifier, VACapacity: limit, homeName: selectedHome.name, priceperKwh: priceperKwH)
        context.insert(homeObj)
        appState.currentHome = homeObj
        let currentHMHome = homelist.homes.first(where: { $0.uniqueIdentifier == appState.currentHome?.id })
        for acc in currentHMHome!.accessories {
            var cat = ""
            switch acc.category.categoryType {
                case HMAccessoryCategoryTypeLightbulb: cat = "Lamp"
                case HMAccessoryCategoryTypeAirConditioner: cat = "AC"
                case  HMAccessoryCategoryTypeTelevision: cat = "Television"
                default: cat = "Others"
            }
            
            let accessoryObj = DeviceModel(id: acc.uniqueIdentifier, name: acc.name, category: cat, VARating: 5, isFromHomeKit: true, home: appState.currentHome!)
            context.insert(accessoryObj)
        }
        
        // MOCK DATA
        let categories = ["Lamp", "Television", "Others", "AC"]
        let VAs = [5, 15, 150, 900]
        for i in 0..<7 {
            let accessoryObj = DeviceModel(id: UUID(), name: "\(appState.currentHome!.homeName) Device \(i)", category: categories[i%4], VARating: VAs[i%4], home: appState.currentHome!)
            let deviceUsageObj = DeviceUsageRecord( startTime: Calendar.current.date(byAdding: .hour, value: -1 * 3 * i, to: Date())!, device: accessoryObj)
            context.insert(accessoryObj)
            context.insert(deviceUsageObj)
        }
        hasCompletedOnboarding = true
        print("Home: \(selectedHome.name) with VA Limit: \(limit)")
    }
}



struct getHome: View {
    @EnvironmentObject private var homelist : HomeStore
    @Binding var selectedHome: HMHome?
    
    var body: some View {
        NavigationStack {
            Group {
                if homelist.homes.isEmpty {
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
//                                .glassEffect()
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
                            .listRowSeparatorTint(Color.white.opacity(0.12))
                        }
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
                }
            }
        }
    }
}



struct SelectElectricity: View {
    
    static let Ecapacity: [String] = ["450 VA","900 VA (Subsidi)","900 VA(Non-subsidi)","1300 VA", "2200 VA", "Others"]
    
    
    static let VAlimit = [
        "450 VA": 450,
        "900 VA (Subsidi)": 900,
        "900 VA(Non-subsidi)": 900,
        "1300 VA": 1300,
        "2200 VA": 2200
    ]
    
    @Binding var isExpanded: Bool
    @Binding var selection: String?
    @Binding var inputLimit: Int?
    
    
    var selectedlimit: Int? {
        guard let selection = selection else { return nil }
        return SelectElectricity.VAlimit[selection]!
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
                List(SelectElectricity.Ecapacity, id: \.self) { capacity in
                    Button(action: {
                        selection = capacity
                        isExpanded = false
                    }) {
                        HStack {
                            Text(capacity)
                                .foregroundColor(capacity == "Others" ? .blue : .primary)
                            Spacer()
                            if selection == capacity {
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
                TextField("Input your VA limit", value: $inputLimit, format: .number)
                    .keyboardType(.numberPad)
                    .padding()
                    .glassEffect(.clear)
                    .cornerRadius(10)
                    .padding(.horizontal,20)
            }
            
            
        }
    }
}


#Preview {
    OnBoardingPage()
}
