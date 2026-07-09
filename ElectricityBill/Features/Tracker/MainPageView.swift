//
//  MainPageView.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 28/06/26.
//

import SwiftUI
import HomeKit
import SwiftData

struct LightningBolt: Shape {
    var cornerRadius: CGFloat = 8.0
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Defined base raw vertex points of the lightning bolt
        let p1 = CGPoint(x: width * 0.60, y: 0)
        let p2 = CGPoint(x: width * 0.05, y: height * 0.55)
        let p3 = CGPoint(x: width * 0.45, y: height * 0.55)
        let p4 = CGPoint(x: width * 0.15, y: height)
        let p5 = CGPoint(x: width * 0.95, y: height * 0.45)
        let p6 = CGPoint(x: width * 0.55, y: height * 0.45)
        
        let points = [p1, p2, p3, p4, p5, p6]
        
        // Loop through points to draw arcs between lines automatically
        path.move(to: CGPoint(x: (p1.x + p6.x) / 2, y: (p1.y + p6.y) / 2))
        
        for i in 0..<points.count {
            let current = points[i]
            let next = points[(i + 1) % points.count]
            path.addArc(tangent1End: current, tangent2End: next, radius: cornerRadius)
        }
        
        path.closeSubpath()
        return path
    }
}

struct LightningBoltView: View {
    @EnvironmentObject var appState: AppState
    
    let usedWatt: Double
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            let progress = usedWatt / (appState.currentHome?.wattLimit() ?? usedWatt)
            LightningBolt()
                .fill(.red.opacity(0.02))
            
            
                .overlay(
                    LightningBolt()
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                        .shadow(color: .white, radius: 5)
                    
                        .shadow(color: .white, radius: 15)
                        .shadow(color: .white, radius: 25)
                )
            
            let start = max(0, min(1, progress - 0.1))
            let middle = max(start, min(1, progress + 0.05))
            LightningBolt()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: start),
                            .init(color: .clear, location: middle),
                            .init(color: .clear, location: 1.0)
                            
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            
                .mask(
                    GeometryReader { geometry in
                        VStack {
                            Spacer(minLength: 0)
                            Rectangle()
                                .frame(height: geometry.size.height * min(1, max(0, progress)))
                        }
                    }
                )
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
        .frame(width: 150, height: 220)
        .padding()
    }
}

struct MainPageView: View {
    @EnvironmentObject private var homeStore: HomeStore
    @EnvironmentObject private var appState: AppState
    @State var expandTotalSpend = false
    @State var totalSpend : Double = 0.0
    @State var showAddHomeSheet : Bool = false
    @Environment(\.modelContext) private var context
    @State var homeObjList: [Home] = []
    
    @State private var newHomeName: String = ""
    
    @State var isExpanded = false
    @State var selection: String? = nil
    @State var inputLimit: Int? = nil
    @State var errorMsg: String = ""
    @State var popUpError: Bool = false
    
    @Binding var showEditHomeSheet: Bool
    
    private var liveUsageSection: some View {
        VStack(alignment: .center, spacing: 10) {
            Spacer()
            HStack {
                Text("\(appState.currentHome?.homeName ?? "Home") - Live Usage").font(Font.title2).bold().padding(.leading, 20)
                Spacer()
            }
            
            let usedWatt = appState.currentHome?.calcCurrentlyUsedWatt() ?? 0
            ZStack {
                usageAxisLabels
                LightningBoltView(usedWatt: usedWatt)
            }
            
            HStack(spacing: 0) {
                let usedWattRounded = Int(usedWatt.rounded())
                Text("\(usedWattRounded)/\(Int(appState.currentHome?.wattLimit() ?? 0)) watt").font(Font.title3).bold()
            }
            
            VStack(spacing: -210) {
                Image("Squiggle1")
                Image("Squiggle2")
            }
            .frame(height: 100)
        }
        .listRowBackground(Color.clear)
    }
    
    private var usageAxisLabels: some View {
        VStack {
            HStack {
                Text("\(Int(appState.currentHome?.wattLimit() ?? 0)) watt").font(Font.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .overlay(Capsule().fill(.clear).stroke(.white.opacity(0.55), lineWidth: 1.0))
                Capsule().fill(Color.white.opacity(0.55)).frame(width: 30, height: 1.5)
            }
            .offset(x: -70)
            Spacer()
            HStack {
                Capsule().fill(Color.white.opacity(0.55)).frame(width: 30, height: 1.5)
                Text("0 watt").font(Font.caption2).foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .overlay(Capsule().fill(.clear).stroke(.white.opacity(0.55), lineWidth: 1.0))
            }
            .offset(x: 30)
        }
        .frame(height: 190)
    }
    
    private var totalSpendSection: some View {
        Group {
            if appState.currentHome?.devices.isEmpty == false {
                VStack(alignment: .leading) {
                    Text("Total Spend").font(Font.title2).bold()
                    totalSpendCard
                }
                .listRowBackground(Color.clear)
            } else {
                HStack {
                    Spacer()
                    Text("Add accessory to your home").font(Font.body)
                    Spacer()
                }
                .padding()
                .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                .listRowBackground(Color.clear)
            }
        }
    }
    
    private var totalSpendCard: some View {
        Button {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                expandTotalSpend.toggle()
            }
        } label: {
            VStack(spacing: 30) {
                totalSpendHeader
                if expandTotalSpend {
                    Capsule().fill(Color.white).frame(height: 1)
                    DetailsView()
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, expandTotalSpend ? 22 : 12)
        .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
    }
    
    private var totalSpendHeader: some View {
        VStack(spacing: -7) {
            HStack(spacing: 20) {
                Image("MoneyBag").resizable().frame(width: 52, height: 59)
                VStack(alignment: .leading) {
                    Text("This Month You Spend").font(Font.headline).bold()
                    Text("\(formatToIDR(amount: totalSpend))").font(Font.headline)
                }
                Spacer()
            }
            HStack {
                Spacer()
                Text(expandTotalSpend ? "close" : "details")
                Image(systemName: expandTotalSpend ? "chevron.up" : "chevron.down")
                    .font(Font.system(size: 12))
                    .foregroundStyle(Color.white)
            }
        }
    }
    
    var isSelectionValid: Bool {
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
    
    private func finishSelectCapacity() {
        guard let limit = resolvedLimit else { return }
        appState.currentHome?.VACapacity = limit
        appState.currentHome?.priceperKwh = OnBoardingPage.priceperKwHDict[selection!]!
        selection = nil
    }
    
    private func getCurrentHMHome() -> HMHome {
        return homeStore.homes.first(where: { $0.uniqueIdentifier == appState.currentHome?.id})!
    }
    
    var body: some View {
            ZStack{
                Image("Background").resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                if appState.currentHome?.VACapacity == 0 {
                    
                    VStack{
                        SelectElectricity(isExpanded: $isExpanded, selection: $selection, inputLimit: $inputLimit)
                        
                        if !isExpanded {
                            Button {
                                finishSelectCapacity()
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
                else{
                    List{
                        Section{liveUsageSection}
                            .frame(height: 500)
                            .listSectionSeparator(.hidden)
                        
                        Section{totalSpendSection}.listSectionSeparator(.hidden)
                        
                        VStack{}.frame(height:100)
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
                        
                    }
                    .listStyle(.plain)
                    
                    .sheet(isPresented: $showAddHomeSheet){
                        AddEditHomeSheet(
                            isPresented: $showAddHomeSheet,
                            newHomeName: $newHomeName,
                            selection: $selection,
                            isExpanded: $isExpanded,
                            popUpError: $popUpError,
                            inputLimit: $inputLimit,
                            errorMsg: $errorMsg,
                            onConfirm: confirmNewHome
                        )
                    }
                    .sheet(isPresented: $showEditHomeSheet){
                        AddEditHomeSheet(
                            isPresented: $showEditHomeSheet,
                            newHomeName: $newHomeName,
                            selection: $selection,
                            isExpanded: $isExpanded,
                            popUpError: $popUpError,
                            inputLimit: $inputLimit,
                            edit: true, errorMsg: $errorMsg,
                            onConfirm: confirmUpdateHome
                        )
                    }
                    .onAppear{
                        totalSpend = calculateTotalSpend()
                    }
                    .onChange(of: homeStore.homes) {
                        totalSpend = calculateTotalSpend()
                    }
                }
            }
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button{
                        showAddHomeSheet.toggle()
                        newHomeName = ""
                        selection = nil
                    }label:{
                        Image(systemName:"plus")
                    }.foregroundStyle(Color.white)
                }
            }
    }
    
    func calculateTotalSpend() -> Double {
        appState.currentHome!.calculateTotalKwH(month: Date()) * appState.currentHome!.priceperKwh!
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
    
    func confirmUpdateHome(activity: String = ""){
        if activity == "delete"{
            let currentHMHome = getCurrentHMHome()
            homeStore.homeManager.removeHome(currentHMHome){ error in
                if let error = error {
                    errorMsg = error.localizedDescription
                    popUpError = true
                }else{
                    context.delete(appState.currentHome!)
                    homeStore.homeManagerDidUpdateHomes(homeStore.homeManager)
                    refreshHomeObjList(updateCurrHome: true, primaryHome: homeStore.primaryHome)
                    print("Successfully remove home")
                }
            }
        }
        else{
            guard let selectedCapacity = selection, newHomeName != "" else { return }
            
            if SelectElectricity.VAlimit.keys.contains(selectedCapacity){
                guard let limit = resolvedLimit else {return}
                appState.currentHome?.VACapacity = limit
                appState.currentHome?.priceperKwh = OnBoardingPage.priceperKwHDict[selectedCapacity]!
            }
            
            if newHomeName != appState.currentHome!.homeName {
                let currentHMHome = homeStore.homes.first(where: {$0.uniqueIdentifier == appState.currentHome?.id})
                currentHMHome?.updateName(newHomeName){error in
                    if let error = error {
                        errorMsg = "Failed to update name: \(error.localizedDescription)"
                        popUpError.toggle()
                    } else {
                        appState.currentHome?.homeName = newHomeName
                        homeStore.isLoaded = false
                        homeStore.homeManagerDidUpdateHomes(homeStore.homeManager)
                        print("Home name updated successfully")
                    }
                }
            }
        }
        showEditHomeSheet = false
    }
    
    func confirmNewHome(activity: String = "") {
        guard let selectedCapacity = selection, let limit = resolvedLimit else { return }
        homeStore.createHome(homeName: newHomeName) { result in
            switch result {
            case .success(let newHome):
                context.insert(Home(
                    id: newHome.uniqueIdentifier,
                    VACapacity: limit,
                    homeName: newHome.name,
                    priceperKwh: OnBoardingPage.priceperKwHDict[selectedCapacity]!
                ))
                refreshHomeObjList(updateCurrHome: true , primaryHome: newHome)
                showAddHomeSheet = false
                homeStore.isLoaded = false
                homeStore.homeManagerDidUpdateHomes(homeStore.homeManager)
            case .failure(let error):
                errorMsg = "Failed to create home: \(error.localizedDescription)"
//                print("Gagal membuat home: \(error.localizedDescription)")
                popUpError.toggle()
            }
        }
    }
}

struct DetailsView: View{
    @EnvironmentObject var appState: AppState
    
    @Query var accessories: [DeviceModel]
    
    var body: some View{
        VStack(spacing: 30){
            
            var groupedItems: [String: [DeviceModel]] {
                Dictionary(grouping: appState.currentHome!.devices, by: \.category)
            }
            let validCategories = sectionOrder.filter { groupedItems[$0] != nil }
            let arr = Array(validCategories.enumerated())
            
            ForEach(arr, id: \.element) { index, categoryType in
                
                
                if let accessories = groupedItems[categoryType]{
                    let totalPerGroup = accessories.reduce(0) { total, accessory in
                        let hoursUsed = accessory.getTotalDuration(month: Date(), unit: .hr)
                        let kilowatts = Double(accessory.VARating!) * 0.8 / 1000.0
                        let electricityRate = appState.currentHome!.priceperKwh!
                        
                        let cost = hoursUsed * kilowatts * electricityRate
                        
                        return total + cost
                    }
                    
                    let rupiahFormatted = formatToIDR(amount: totalPerGroup)
                    
                    HStack(spacing: 20){
                        let logoName = logoNames[categoryType]!
                        Image(systemName: logoName).font(Font.system(size: 35, weight: .thin))
                        VStack(alignment:.leading){
                            Text(categoryType).font(Font.subheadline).bold()
                            Text("\(rupiahFormatted)").font(Font.body.weight(.medium))
                        }
                        Spacer()
                    }
                    
                    let validCategoriesLen = validCategories.count - 1
                    if index < validCategoriesLen{
                        Capsule().fill(Color.white).frame(height: 0.7).padding(.trailing, 22)
                    }
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            
        }
    }
}

struct SelectElectricityCapacity: View {
    
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

struct AddEditHomeSheet: View {
    @Binding var isPresented: Bool
    @Binding var newHomeName: String
    @Binding var selection: String?
    @Binding var isExpanded: Bool
    @Binding var popUpError: Bool
    @Binding var inputLimit: Int?
    @State var edit: Bool = false
    @EnvironmentObject var appState: AppState
    @Binding var errorMsg: String
    @EnvironmentObject var homeStore: HomeStore
    @Environment(\.modelContext) var context
    var onConfirm: (String) -> Void
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 30) {
                header
                VStack(alignment: .leading){
                    Text("Home Name").font(Font.headline).bold()
                    nameField
                }
                VStack(alignment: .leading){
                    Text("Select Electricity Capacity").font(Font.headline).bold()
                    SelectElectricityCapacity(isExpanded: $isExpanded, selection: $selection, inputLimit: $inputLimit)
                }
                
                Spacer()
                
                HStack{
                    Spacer()
                    Button(action: {onConfirm("delete")}){
                        Text("Delete").foregroundStyle(Color.red)
                    }
                    Spacer()
                }
            }
            .padding()
            .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
            
            if popUpError {
                errorOverlay
            }
        }.onAppear{
            newHomeName = appState.currentHome?.homeName ?? ""
            selection = "\(appState.currentHome?.VACapacity ?? 0)"
            errorMsg = ""
        }
    }
    
    private var header: some View {
        HStack {
            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .glassEffect(.clear)
            Spacer()
            Text(edit ? "\(appState.currentHome?.homeName ?? "") Setting" : "Add New Home").font(Font.headline).bold()
            Spacer()
            Button(action: {onConfirm("")}) {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .glassEffect(.clear)
        }
    }
    
    private var nameField: some View {
        TextField("Home Name", text: $newHomeName)
            .padding(12)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var errorOverlay: some View {
        VStack {
            Text(errorMsg)
            Button{
                popUpError.toggle()
            }label:{
                Text("Close")
            }
            .padding()
            .background(Color.red).clipShape(Capsule())
        }.padding().glassEffect(.clear, in: .rect(cornerRadius: 12.0))
    }
}

//#Preview {
//    let container = try! ModelContainer(
//        for: Home.self,
//        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
//    )
//    return MainPageView()
//        .environmentObject(HomeStore())
//        .modelContainer(container)
//}
