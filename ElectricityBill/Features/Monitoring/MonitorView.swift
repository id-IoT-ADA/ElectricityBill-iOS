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
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 20){
            Image(systemName: logoName).font(Font.system(size: 35, weight: .thin)).frame(width: 50)
            VStack(alignment:.leading){
                Text(topText).bold().lineLimit(1)
                Text(bottomText).lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: $isOn).tint(.blue).labelsHidden()
        }
    }
}

struct MonitoringView: View {
    @EnvironmentObject private var homeStore: HomeStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var context
    @State private var showAddDevice = false
    @State var searchText: String = ""
    @Query(
        filter: #Predicate<DeviceModel> {
                $0.deletedAt == nil
            },
        sort: \.createdAt
    ) var visibleAccessories : [DeviceModel]
    
    private var listAccessoriesSection: some View {
        VStack(spacing: 20){
            ForEach(visibleAccessories.filter {
                $0.home == appState.currentHome && (searchText == "" || $0.name.localizedCaseInsensitiveContains(searchText))
                
            })  {accessory in
                if accessory.home == appState.currentHome && accessory.deletedAt == nil {
                    @Bindable var bindableAccessory = accessory
                    
                    if let currHMHome = homeStore.homes.first(where: { $0.uniqueIdentifier == appState.currentHome!.id}), let hmAcc = currHMHome.accessories.first(where: {$0.uniqueIdentifier == accessory.id}){
                        NavigationLink {
                            DeviceEnergyView(accessory: hmAcc, context: context)
                                .navigationTitle(accessory.name)
                        } label: {
                            DeviceItemLayout(logoName: logoNames[accessory.category]!, topText: accessory.name, bottomText: " V, mA", isOn: $bindableAccessory.isActive)
                        }
                        .padding()
                        .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                        
                    }
                    //APUS KL UDH GA ADA MOCK DATA
                    else{
                        NavigationLink {
                            EmptyView()
                        } label: {
                            DeviceItemLayout(logoName: logoNames[accessory.category]!, topText: accessory.name, bottomText: " V, mA", isOn: $bindableAccessory.isActive)
                        }
                        .padding()
                        .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
            
        }
//        .listRowBackground(Color.clear)
        
    }
    
    var body: some View {
        NavigationStack {
            ZStack{
                Image("Background").resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                List{
//                    Section{
//                        ScrollView(.horizontal){
////                            Capsule
//                        }
//                    }
                    
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
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddDevice = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            
            .navigationLinkIndicatorVisibility(.hidden)
        }
        
    }
}

//#Preview {
//    MonitoringView()
//}
