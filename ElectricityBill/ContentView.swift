//
//  ContentView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 25/06/26.
//

import SwiftUI
import SwiftData
import HomeKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var homeStore: HomeStore
    @EnvironmentObject private var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State var homeObjList: [Home] = []

    var toolbarContent: some View {
//        ToolbarItem(placement: .topBarTrailing){
            Menu{
                ForEach(homeObjList, id: \.self){ home in
                    Button{
                        appState.currentHome = home
                    }label:{
                        Text(home.homeName)
                        if appState.currentHome! == home{
                            Text("Current Location").font(Font.caption2)
                            Image(systemName: "checkmark")
                        }
                        
                    }
                }
            }label:{
                Image(systemName: "ellipsis")
            }.foregroundStyle(Color.white)
//        }
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if homeStore.isLoaded{
                        TabView {
                            Tab("Home", systemImage: "house.fill"){
                                NavigationStack{
                                    MainPageView()
                                        .toolbar(
                                            appState.currentHome?.VACapacity == 0 ? .hidden : .visible,
                                            for: .tabBar
                                        )
                                        .toolbar{
                                            ToolbarItem(placement: .topBarTrailing){
                                                toolbarContent
                                            }
                                        }
                                }
                            }
                            Tab("Monitor", systemImage: "inset.filled.rectangle.and.person.filled") {
                                NavigationStack{
                                    MonitoringView()
                                        .toolbar(
                                            appState.currentHome?.VACapacity == 0 ? .hidden : .visible,
                                            for: .tabBar
                                        )
                                        .toolbar{
                                            ToolbarItem(placement: .topBarTrailing){
                                                toolbarContent
                                            }
                                        }
                                }
                            }
                            Tab("Insight", systemImage: "lightbulb.circle.fill") {
                                NavigationStack{
                                    InsightView()
                                        .toolbar(
                                            appState.currentHome?.VACapacity == 0 ? .hidden : .visible,
                                            for: .tabBar
                                        )
                                        .toolbar{
                                            ToolbarItem(placement: .topBarTrailing){
                                                toolbarContent
                                            }
                                        }
                                }
                            }
                        }
                        .foregroundStyle(Color(.white))
                        .onAppear(perform: updateSwiftHomeData)
                        .onChange(of: homeStore.homes) {
                            updateSwiftHomeData()
                        }
                }
                else{
                    ProgressView("Loading Homekit...").background(
                        Image("Background").resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    )
                }
            } else {
                WelcomePage()
            }
        }
    }
    
    func updateSwiftHomeData(){
        let descriptor = FetchDescriptor<Home>()
        do {
            var items = try context.fetch(descriptor)
            let idsInData = Set(items.map(\.id))
            var primaryHome: HMHome? = nil
            var updateCurrHome: Bool = false
            
            for home in homeStore.homes {
                if !idsInData.contains(home.uniqueIdentifier) {
                    print("add: \(home.name)")
                    // Default kwHlimit untuk home yang muncul dari luar app (bukan lewat sheet ini,
                    // misalnya dibuat via Home app) — user bisa edit limitnya nanti.
                    let homeObj = Home(id: home.uniqueIdentifier, VACapacity: 0, homeName: home.name, priceperKwh: 0)
                    context.insert(homeObj)
                    
                    for acc in home.accessories {
                        var cat = ""
                        switch acc.category.categoryType {
                        case HMAccessoryCategoryTypeLightbulb: cat = "Lamp"
                        case HMAccessoryCategoryTypeAirConditioner: cat = "AC"
                        case  HMAccessoryCategoryTypeTelevision: cat = "Television"
                        default: cat = "Others"
                        }
                        
                        let accessoryObj = DeviceModel(id: acc.uniqueIdentifier, name: "\(acc.name)", category: cat, VARating: 5, home: homeObj)
                        context.insert(accessoryObj)
                    }
                    // MOCK DATA
                    let categories = ["Lamp", "Television", "Others", "AC"]
                    let VAs = [5, 15, 150, 900]
                    for i in 0..<7 {
                        
                        let accessoryObj = DeviceModel(id: UUID(), name: "\(home.name) Device \(i)", category: categories[i%4], VARating: VAs[i%4], home: homeObj)
                        
                        let deviceUsageObj = DeviceUsageRecord(startTime: Calendar.current.date(byAdding: .hour, value: -1 * 3 * i, to: Date())!, device: accessoryObj)
                        context.insert(accessoryObj)
                        context.insert(deviceUsageObj)
                    }
                }
                if home.isPrimary {
                    primaryHome = home
                }
            }
            
            // Hapus entry yang HMHome-nya sudah tidak ada — match by id, bukan nama
            items = try context.fetch(descriptor)
            let currentHomeKitIDs = Set(homeStore.homes.map(\.uniqueIdentifier))
            for homeObj in items where !currentHomeKitIDs.contains(homeObj.id) {
                print("delete: \(homeObj.homeName)")
                if (appState.currentHome == homeObj){ updateCurrHome = true }
                context.delete(homeObj)
            }
            
            refreshHomeObjList(updateCurrHome: updateCurrHome, primaryHome: primaryHome)
        } catch {
            print(error)
        }
    }
    
    func refreshHomeObjList(updateCurrHome: Bool, primaryHome: HMHome? = nil) {
        let descriptor = FetchDescriptor<Home>(sortBy: [SortDescriptor(\.homeName)])
        do {
            let items = try context.fetch(descriptor)
            homeObjList = items
            if updateCurrHome || appState.currentHome == nil {
                appState.currentHome = homeObjList.first(where: { $0.id == primaryHome?.uniqueIdentifier})
            }
        } catch {
            print(error)
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Home.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ContentView()
        .environmentObject(HomeStore())
        .modelContainer(container)
}
