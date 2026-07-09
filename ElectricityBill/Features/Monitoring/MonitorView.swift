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
    @Environment(\.modelContext) private var context
    @Binding var showAlert: Bool
    let device: DeviceModel
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
                    
                    device.isActive = newValue
                }
            )).tint(.blue).labelsHidden()
                .onChange(of: device.isActive) {
                    if device.isActive == true {
                        let newUsageRecord = DeviceUsageRecord(startTime: Date(), device: device)
                        context.insert(newUsageRecord)
                    }
                    else{
                        device.usageRecords.last?.endTime = Date()
                    }
                }
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
                    DeviceEnergyView(accessory: hmAcc, context: context)
                        .navigationTitle(accessory.name)
                } label: {
                    DeviceItemLayout(logoName: logoNames[accessory.category]!, topText: accessory.name, bottomText: "\(accessory.VARating ?? 0) VA", showAlert: $showAlert, device: accessory){ newValue in
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
                    selectedAccessory?.isActive = true
                }
                Button("Cancel", role: .destructive) {
//                    print("Item deleted.")
                }
            } message: {
                let progress = (appState.currentHome?.calcCurrentlyUsedWatt() ?? 0) / (appState.currentHome?.wattLimit() ?? 0) * 100
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
        return visibleAccessories.filter {
            $0.home == appState.currentHome && (searchText == "" || $0.name.localizedCaseInsensitiveContains(searchText))
            && (searchCategory == "" || $0.category.lowercased() == searchCategory.lowercased())
            
        }
    }
}

//#Preview {
//    MonitoringView()
//}
