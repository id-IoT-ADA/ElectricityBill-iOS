//
//  MainPageView.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 28/06/26.
//

import SwiftUI
import HomeKit
import SwiftData
import Foundation

func textStyle(text: String, size: Int = 12, weight: Font.Weight = Font.Weight.regular, color: Color = Color.white) -> Text{
    return Text(text).font(Font.system(size: CGFloat(size), weight: weight)).foregroundColor(color)
}

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
    
    @State var usedWatt: Double
    
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
    @State var usedWatt: Double = 0.0
    @State var expandTotalSpend = false
    @State var totalSpend : Double = 0.0
    @State var showAddHomeSheet : Bool = false
    let preferredOrder = [
        HMAccessoryCategoryTypeLightbulb,
        HMAccessoryCategoryTypeAirConditioner,
        HMAccessoryCategoryTypeTelevision
    ]
    @Environment(\.modelContext) private var context
    @State var homeObjList: [Home] = []
    
    @State private var newHomeName: String = ""
    
    @State var isExpanded = false
    @State var selection: String? = nil
    @State var inputLimit: Int? = nil
    @State var res : [String] = ["", ""]
    @State var popUpError: Bool = false
    
    @Query(
        filter: #Predicate<DeviceModel> { device in
            device.isActive == true
        }) var activeAccessories: [DeviceModel]
    
    func calcUsedWatt() -> Double {
        var runningWatt: Double = 0.0
        for acc in activeAccessories{
            if acc.home == appState.currentHome{ runningWatt += Double(acc.VARating!) * 0.8}
        }
        return runningWatt
    }
    
    private var liveUsageSection: some View {
        VStack(alignment: .center, spacing: 10) {
            Spacer()
            HStack {
                textStyle(text: "Live Usage", size: 25, weight: .semibold)
                    .padding(.leading, 20)
                Spacer()
            }
            
            ZStack {
                usageAxisLabels
                LightningBoltView(usedWatt: calcUsedWatt())
            }
            
            HStack(spacing: 0) {
                let usedWattRounded = Int(calcUsedWatt().rounded())
                textStyle(text: "\(usedWattRounded)", size: 21, weight: .bold)
                textStyle(text: "/\(appState.currentHome?.wattLimit() ?? 0) watt", size: 21)
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
                textStyle(text: "\(appState.currentHome?.wattLimit() ?? 0) watt", size: 12, color: .white.opacity(0.55))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .overlay(Capsule().fill(.clear).stroke(.white.opacity(0.55), lineWidth: 1.0))
                Capsule().fill(Color.white.opacity(0.55)).frame(width: 30, height: 1.5)
            }
            .offset(x: -70)
            Spacer()
            HStack {
                Capsule().fill(Color.white.opacity(0.55)).frame(width: 30, height: 1.5)
                textStyle(text: "0 watt", size: 12, color: .white.opacity(0.55))
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
                    textStyle(text: "Total Spend", size: 25, weight: .semibold)
                    totalSpendCard
                }
                .listRowBackground(Color.clear)
            } else {
                HStack {
                    Spacer()
                    textStyle(text: "Add accessory to your home")
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
                    textStyle(text: "This Month You Spend", size: 18, weight: .semibold)
                    textStyle(text: "\(formatToIDR(amount: totalSpend))", size: 18)
                }
                Spacer()
            }
            HStack {
                Spacer()
                textStyle(text: expandTotalSpend ? "close" : "details")
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
    
    var body: some View {
        NavigationStack{
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
                        AddHomeSheet(
                            isPresented: $showAddHomeSheet,
                            newHomeName: $newHomeName,
                            selection: $selection,
                            isExpanded: $isExpanded,
                            popUpError: $popUpError,
                            inputLimit: $inputLimit,
                            res: res,
                            onConfirm: confirmNewHome
                        )
                    }
                    .onAppear{
                        updateSwiftHomeData()
                        totalSpend = calculateTotalSpend()
                    }
                    .onChange(of: homeStore.homes) { _ in
                        updateSwiftHomeData()
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
                
                ToolbarItem(placement: .topBarTrailing){
                    Menu{
                        ForEach(homeObjList, id: \.self){ home in
                            Button{
                                appState.currentHome = home
                            }label:{
                                textStyle(text: home.homeName, size: 16)
                                if appState.currentHome! == home{
                                    textStyle(text: "Current Location", size: 12)
                                    Image(systemName: "checkmark")
                                }
                                
                            }
                        }
                    }label:{
                        Image(systemName: "ellipsis")
                    }.foregroundStyle(Color.white)
                }
            }
        }
        
    }
    
    func calculateTotalSpend() -> Double {
        appState.currentHome!.calculateTotalKwH(month: Date()) * appState.currentHome!.priceperKwh!
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
    
    /// Refresh murah: cuma re-fetch + sort + publish ke homeObjList.
    /// Aman dipanggil langsung setelah insert home baru, tanpa menunggu homeStore.homes sync.
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
    
    func confirmNewHome() {
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
                print("Gagal membuat home: \(error.localizedDescription)")
                popUpError.toggle()
            }
        }
    }
}

func formatToIDR(amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "id_ID")
    formatter.currencySymbol = "Rp "
    
    
    if let finalString = formatter.string(from: NSNumber(value: amount)){
        return finalString
    }
    else{
        return "Rp "
    }
}

let logoNames = [
    "Lamp" : "lightbulb.min",
    "AC" : "air.conditioner.horizontal",
    "Television" : "tv",
    "Others" : "macbook.and.iphone"
]

struct DetailsView: View{
    @EnvironmentObject var appState: AppState
    
    private let sectionOrder: [String] = ["Lamp", "AC", "Television", "Others"]
    
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
                            textStyle(text: categoryType, size: 15, weight: .semibold)
                            textStyle(text: "\(rupiahFormatted)", size: 15)
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
        //            .padding(.horizontal,20)
        
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
            //                .padding(.horizontal, 20)
        }
        if selection == "Others"{
            TextField("Input your VA limit", value: $inputLimit, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .padding()
                .transition(.opacity)
        }
        
        
        
    }
}

struct AddHomeSheet: View {
    @Binding var isPresented: Bool
    @Binding var newHomeName: String
    @Binding var selection: String?
    @Binding var isExpanded: Bool
    @Binding var popUpError: Bool
    @Binding var inputLimit: Int?
    var res: [String]
    var onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 30) {
                header
                VStack(alignment: .leading){
                    textStyle(text: "Home Name", size: 16, weight: .bold)
                    nameField
                }
                VStack(alignment: .leading){
                    textStyle(text: "Select Electricity Capacity", size: 16, weight: .bold)
                    SelectElectricityCapacity(isExpanded: $isExpanded, selection: $selection, inputLimit: $inputLimit)
                }
                
                Spacer()
            }
            .padding()
            .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
            
            if popUpError {
                errorOverlay
            }
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
            textStyle(text: "Add New Home", size: 17, weight: .bold)
            Spacer()
            Button(action: onConfirm) {
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
            Text(res[1])
            Button("Close") { popUpError.toggle() }
                .padding()
                .background(Color.blue)
        }.padding()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Home.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return MainPageView()
        .environmentObject(HomeStore())
        .modelContainer(container)
}
