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
    @State private var showEditHomeSheet = false
    
    var toolbarContent: some View {
        Menu{
            Button{
                showEditHomeSheet = true
            }label:{
                Text("Edit Home")
                Image(systemName: "gear")
                
            }
            
            Divider()
            
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
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if homeStore.isLoaded{
                    mainTabView
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
    
    private var mainTabView: some View {
        TabView {
            Tab("Home", systemImage: "house.fill"){
                tab(MainPageView(showEditHomeSheet: $showEditHomeSheet))
            }
            Tab("Monitor", systemImage: "inset.filled.rectangle.and.person.filled") {
                tab(MonitoringView())
            }
            Tab("Insight", systemImage: "lightbulb.circle.fill") {
                tab(InsightView())
            }
        }
        .foregroundStyle(Color(.white))
        .onAppear(perform: updateSwiftHomeData)
        .onChange(of: homeStore.homes) {
            updateSwiftHomeData()
        }
        // Accessory baru dipairing tidak mengubah daftar `homes`,
        // jadi picu sync juga saat ada pairing yang baru selesai.
        .onChange(of: homeStore.lastPairedAccessoryID) {
            updateSwiftHomeData()
        }
        // Perubahan accessory dari Home app (tambah/hapus) juga tidak
        // mengubah `homes`; token ini yang menandainya.
        .onChange(of: homeStore.homeContentsRevision) {
            updateSwiftHomeData()
        }
    }
    
    /// Membungkus konten sebuah tab dalam NavigationStack dengan toolbar yang sama.
    @ViewBuilder
    private func tab(_ content: some View) -> some View {
        NavigationStack {
            content
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
    
    /// Memetakan kategori HomeKit ke string kategori internal app.
    func category(for accessory: HMAccessory) -> String {
        switch accessory.category.categoryType {
        case HMAccessoryCategoryTypeLightbulb: return "Lamp"
        case HMAccessoryCategoryTypeAirConditioner: return "AC"
        case HMAccessoryCategoryTypeTelevision: return "Television"
        default: return "Others"
        }
    }
    
    func updateSwiftHomeData(){
        let descriptor = FetchDescriptor<Home>()
        do {
            var items = try context.fetch(descriptor)
            var primaryHome: HMHome? = nil
            var updateCurrHome: Bool = false
            
            for home in homeStore.homes {
                let homeObj: Home
                if let existing = items.first(where: { $0.id == home.uniqueIdentifier }) {
                    // Home sudah ada di SwiftData — cukup pakai object-nya.
                    homeObj = existing
                } else {
                    print("add: \(home.name)")
                    // Default kwHlimit untuk home yang muncul dari luar app (bukan lewat sheet ini,
                    // misalnya dibuat via Home app) — user bisa edit limitnya nanti.
                    let newHome = Home(id: home.uniqueIdentifier, VACapacity: 0, homeName: home.name, priceperKwh: 0)
                    context.insert(newHome)
                    homeObj = newHome
                    
                    // MOCK DATA — hanya untuk home yang baru pertama kali muncul.
                    let categories = ["Lamp", "Television", "Others", "AC"]
                    let VAs = [5, 15, 150, 900]
                    for i in 0..<7 {
                        
                        let accessoryObj = DeviceModel(id: UUID(), name: "\(home.name) Device \(i)", category: categories[i%4], VARating: VAs[i%4], home: homeObj)
                        
                        let deviceUsageObj = DeviceUsageRecord(startTime: Calendar.current.date(byAdding: .hour, value: -1 * 3 * i, to: Date())!, device: accessoryObj)
                        context.insert(accessoryObj)
                        context.insert(deviceUsageObj)
                    }
                }
                
                // Sinkronisasi accessory secara idempotent: buat DeviceModel untuk
                // setiap HMAccessory yang belum punya record — baik di home baru
                // maupun home lama (mis. accessory yang baru saja dipairing).
                let existingAccIDs = Set(homeObj.devices.map(\.id))
                for acc in home.accessories where !existingAccIDs.contains(acc.uniqueIdentifier) {
                    print("add accessory: \(acc.name)")
                    // VARating awal 0; nanti dikalibrasi sekali dari arus nyata
                    // (lihat EnergyMonitor) setelah accessory mengalirkan arus.
                    let accessoryObj = DeviceModel(id: acc.uniqueIdentifier, name: "\(acc.name)", category: category(for: acc), VARating: 0, isFromHomeKit: true, home: homeObj)
                    context.insert(accessoryObj)
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
