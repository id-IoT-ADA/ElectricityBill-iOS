//
//  MonitorView.swift
//  ElectricityBill
//
//  Created by Ikhwan on 01/07/26.
//

import SwiftUI
import HomeKit
import SwiftData

struct DeviceItemLayout: View {
    @State var logoName: String
    @State var topText: String
    @State var bottomText: String
    @State var topWeight: Font = Font.body
    @State var bottomWeight: Font = Font.subheadline
    @Binding var showAlert: Bool
    let device: DeviceModel
    /// Untuk device HomeKit: menulis state on/off ke accessory nyata (relay ESP32),
    /// sama seperti kontrol di DeviceEnergyView. Nil untuk mock device.
    var onSetPower: ((Bool) -> Void)? = nil
    let onToggle: (Bool) -> Void
    
    func canTurnOn(_ device: DeviceModel) -> Bool {
        let deviceWatt = Double(device.VARating!) * 0.8
        let currentlyUsedWatt = device.home?.calcCurrentlyUsedWatt() ?? 0
        let safeLimit = (device.home?.wattLimit() ?? 0) - 10
        return currentlyUsedWatt + deviceWatt <= safeLimit
    }
    
    var body: some View {
        HStack(spacing: 20){
            Image(systemName: logoName).font(Font.system(size: 35, weight: .thin)).frame(width: 50)
            VStack(alignment:.leading){
                Text(topText).bold().lineLimit(1)
                Text(bottomText).lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { device.isActive },
                set: { newValue in
                    if newValue {
                        guard canTurnOn(device) else {
                            showAlert = true
                            onToggle(newValue)
                            return
                        }
                    }

                    // Satu jalur: setActive mengurus state + usage record sekaligus.
                    device.setActive(newValue)
                    // Kontrol lampu nyata (HomeKit) — setara dengan toggle di detail view.
                    onSetPower?(newValue)
                }
            )).tint(.blue).labelsHidden()
        }
    }
}

struct MonitoringView: View {
    @EnvironmentObject private var homeStore: HomeStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var context
    @State private var showAddDevice = false
    @State var searchText: String = ""
    @State var searchCategory: String = ""
    @State var filteredAccessories : [DeviceModel] = []
    @State var showAlert: Bool = false
    @State var selectedAccessory: DeviceModel? = nil
    @Query(
        filter: #Predicate<DeviceModel> {
            $0.deletedAt == nil
        },
        sort: \.createdAt
    ) var visibleAccessories : [DeviceModel]
    
    private var listAccessoriesSection: some View {
        ForEach(filteredAccessories)  {accessory in
            if let currHMHome = homeStore.homes.first(where: { $0.uniqueIdentifier == appState.currentHome!.id}), let hmAcc = currHMHome.accessories.first(where: {$0.uniqueIdentifier == accessory.id}){
                NavigationLink {
                    DeviceEnergyView(accessory: hmAcc, device: accessory, context: context)
                        .navigationTitle(accessory.name)
                } label: {
                    DeviceItemLayout(logoName: logoNames[accessory.category]!, topText: accessory.name, bottomText: "\(accessory.VARating ?? 0) VA", showAlert: $showAlert, device: accessory, onSetPower: { homeStore.setPower($0, for: hmAcc) }){ newValue in
                        selectedAccessory = accessory
                    }
                }
                .padding()
                .glassEffect(.clear, in: .rect(cornerRadius: 12.0))

            }
            //APUS KL UDH GA ADA MOCK DATA
            else{
                NavigationLink {
                    EmptyView()
                } label: {
                    DeviceItemLayout(logoName: logoNames[accessory.category]!, topText: accessory.name, bottomText: " V, mA", showAlert: $showAlert, device: accessory){ newValue in
                        selectedAccessory = accessory
                    }
                }
                .padding()
                .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
            }
        }
        .onDelete(perform: deleteDevice)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .scrollContentBackground(.hidden)
        
    }
    
    func deleteDevice(at offsets: IndexSet) {
        for index in offsets {
            let itemToDelete = filteredAccessories[index]
            itemToDelete.deletedAt = Date()
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack{
                Image("Background").resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                
                if filteredAccessories.isEmpty{
                    VStack(spacing: 35){
                        Image("Box")
                        VStack(spacing: 20){
                            Text("There are no appliances here").font(Font.headline)
                            Text("Start adding your appliances").font(Font.subheadline)
                        }
                        Button{
                            showAddDevice = true
                        }label: {
                            Text("Add appliances").font(Font.subheadline)
                        }.padding()
                            .background(.white.opacity(0.3))
                            .clipShape(Capsule())
                            .glassEffect(.clear, in: .capsule)
                    }
                }
                else{
                    List{
                        VStack{}.frame(height:100)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listSectionSeparator(.hidden)
                        
                        VStack{
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack(spacing: 20){
                                    Button{
                                        searchCategory = ""
                                    }label: {
                                        Text("All").font(Font.headline)
                                    }.padding(.horizontal, 10).padding(.vertical, 2)
                                        .background(searchCategory == "" ? .white.opacity(0.3) : .clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                                    
                                    ForEach(sectionOrder, id: \.self){section in
                                        Button{
                                            searchCategory = section
                                        }label: {
                                            Text(section).font(Font.headline)
                                        }.padding(.horizontal, 10).padding(.vertical, 2)
                                            .background(searchCategory == section ? .white.opacity(0.3) : .clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listSectionSeparator(.hidden)
                        
                        Section{
                            listAccessoriesSection
                        }.listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
                        
                        VStack{}.frame(height:100)
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
                    }
                    .sheet(isPresented: $showAddDevice) {AddDeviceView()}
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search accessories...")
                    .searchDictationBehavior(.inline(activation: .onSelect))
                }
            }
            .onAppear{
                filteredAccessories = filterAccessories()
            }
            .onChange(of: [searchText, searchCategory]){
                filteredAccessories = filterAccessories()
            }
            .onChange(of: appState.currentHome){
                filteredAccessories = filterAccessories()
            }
            // Device baru dari sync SwiftData (mis. accessory hasil pairing) —
            // recompute agar langsung muncul dan ter-sort ke atas.
            .onChange(of: visibleAccessories.count){
                filteredAccessories = filterAccessories()
            }
            // Isi HomeKit berubah (tambah/hapus lewat Home app) — refresh sort.
            .onChange(of: homeStore.homeContentsRevision){
                filteredAccessories = filterAccessories()
            }
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddDevice = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDevice) {AddDeviceView()}
            .navigationLinkIndicatorVisibility(.hidden)
            .alert("Power Usage Warning!", isPresented: $showAlert) {
                Button("Turn On", role: .cancel) {
                    guard let acc = selectedAccessory else { return }
                    acc.setActive(true)
                    // Konsisten dengan toggle biasa: kontrol lampu HomeKit nyata.
                    if let hmHome = homeStore.homes.first(where: { $0.uniqueIdentifier == appState.currentHome?.id }),
                       let hmAcc = hmHome.accessories.first(where: { $0.uniqueIdentifier == acc.id }) {
                        homeStore.setPower(true, for: hmAcc)
                    }
                }
                Button("Cancel", role: .destructive) {
//                    print("Item deleted.")
                }
            } message: {
                let progress = (appState.currentHome?.calcCurrentlyUsedWatt() ?? 1) / (appState.currentHome?.wattLimit() ?? 0)
                Text("You've used \(Int(progress))% of your PLN capacity. Turning \(selectedAccessory?.name ?? "this device") on might cause a sudden blackout.")
                
//                Text("You've used \(Int(progress))% of your PLN capacity. Turning ")
//                +
//                Text(selectedAccessory?.name ?? "this device")
//                    .bold()
//                +
//                Text(" on might cause a sudden blackout.")
            }
        }
        
    }
    
    func filterAccessories() -> [DeviceModel]{
        // ID accessory HomeKit yang benar-benar ada di home aktif SEKARANG — dipakai
        // untuk sorting, sehingga tidak bergantung pada flag tersimpan yang bisa basi.
        let homeKitIDs: Set<UUID> = {
            guard let currentID = appState.currentHome?.id,
                  let hmHome = homeStore.homes.first(where: { $0.uniqueIdentifier == currentID })
            else { return [] }
            return Set(hmHome.accessories.map(\.uniqueIdentifier))
        }()

        return visibleAccessories.filter {
            $0.home == appState.currentHome && (searchText == "" || $0.name.localizedCaseInsensitiveContains(searchText))
            && (searchCategory == "" || $0.category.lowercased() == searchCategory.lowercased())

        }
        // Accessory HomeKit nyata tampil di paling atas; sisanya (mock) menyusul.
        // Tiebreaker createdAt menjaga urutan dalam tiap grup tetap stabil
        // (sorted(by:) di Swift tidak dijamin stable).
        .sorted { a, b in
            let aHK = homeKitIDs.contains(a.id)
            let bHK = homeKitIDs.contains(b.id)
            if aHK != bHK { return aHK }
            return a.createdAt < b.createdAt
        }
    }
}

//#Preview {
//    MonitoringView()
//}
