//
//  MainPageView.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 28/06/26.
//

import SwiftUI
import HomeKit
import SwiftData

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

struct MainPageView: View {
    //    @State var progress: CGFloat = 0.0
    @EnvironmentObject private var homeStore: HomeStore
    @State var usedkWh: Double = 0.0
    @State var expandTotalSpend = false
    @State var showAddHomeSheet : Bool = false
    let preferredOrder = [
        HMAccessoryCategoryTypeLightbulb,
        HMAccessoryCategoryTypeAirConditioner,
        HMAccessoryCategoryTypeTelevision
    ]
    @Environment(\.modelContext) private var context
    @State var homeObjList: [Home] = []
    
    private var lastActiveCategory = "Others"
    
    private let sectionOrder: [String] = ["Lamp", "AC", "Television", "Others"]
    
    private let logoNames = [
        "Lamp" : "lightbulb.min",
        "AC" : "air.conditioner.horizontal",
        "Television" : "tv"
    ]
    
    @State private var newHomeName: String = ""
    
    @State var currentHome: Home?
    @State var currentHMHome: HMHome?
    
    let Ecapacity = ["450 VA","900 VA (Subsidi)","900 VA(Non-subsidi)","1300 - 2200 VA", ">3500 VA"  ]
    let EcapacityDict = [
        "450 VA" : 450,
        "900 VA (Subsidi)" : 900,
        "900 VA(Non-subsidi)" : 900,
        "1300 - 2200 VA" : 2200,
        ">3500 VA" : 3500
    ]
    @State var isExpanded = false
    @State var selection: String? = nil
    @State var res : [String] = ["", ""]
    @State var popUpError: Bool = false

    
    var body: some View {
        NavigationStack{
            ZStack{
                Image("Background").resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                List{
                    Section{
                        VStack(alignment: .center, spacing: 10){
                            Spacer()
                            HStack{
                                textStyle(text: "Live Usage", size: 25, weight: .semibold).padding(.leading, 20)
                                Spacer()
                            }
                            
                            ZStack{
                                
                                VStack{
                                    HStack{
                                        textStyle(text:"\(currentHome?.kwHlimit ?? 1200)", size: 12, color: .white.opacity(0.55))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2)
                                            .overlay(Capsule().fill(.clear).stroke(.white.opacity(0.55), lineWidth: 1.0))
                                        Capsule().fill(Color.white.opacity(0.55)).frame(width: 30, height: 1.5)
                                    }
                                    .offset(x: -70)
                                    Spacer()
                                    HStack{
                                        Capsule().fill(Color.white.opacity(0.55)).frame(width: 30, height: 1.5)
                                        textStyle(text:"0 kWh", size: 12, color: .white.opacity(0.55))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2)
                                            .overlay(Capsule().fill(.clear).stroke(.white.opacity(0.55), lineWidth: 1.0))
                                    }
                                    .offset(x: 30)
                                }
                                .frame(height: 190)
                                
                                ZStack(alignment: .bottom) {
                                    let progress = usedkWh / 120.0
                                    LightningBolt()
                                        .fill(.red.opacity(0.02))
                                    
                                    
                                        .overlay(
                                            LightningBolt()
                                                .stroke(.white.opacity(0.3), lineWidth: 2)
                                                .shadow(color: .white, radius: 5)
                                            
                                                .shadow(color: .white, radius: 15)
                                                .shadow(color: .white, radius: 25)
                                        )
                                    
                                    
                                    LightningBolt()
                                        .fill(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .white, location: progress - 0.1),
                                                    .init(color: .clear, location: progress + 0.05),
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
                                                        .frame(height: geometry.size.height * progress)
                                                }
                                            }
                                        )
                                        .animation(.easeInOut(duration: 1.0), value: progress)
                                }
                                .frame(width: 150, height: 220)
                                .padding()
                            }
                            
                            HStack(spacing:0){
                                textStyle(text:"\(Int(usedkWh.rounded()))", size: 21, weight: .bold)
                                textStyle(text:"/1200 kWh", size: 21)
                            }
                            
                            VStack(spacing: -210){
                                Image("Squiggle1")
                                Image("Squiggle2")
                            }.frame(height:100)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .frame(height: 500)
                    .listSectionSeparator(.hidden)
                    
                    Section{
                        
                        if currentHMHome?.accessories.isEmpty == false{
                            VStack(alignment: .leading){
                                textStyle(text: "Total Spend", size: 25, weight: .semibold)
                                
                                Button{
                                    withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                                        expandTotalSpend.toggle()
                                    }
                                }label:{
                                    VStack(spacing: 30){
                                        VStack(spacing: -7){
                                            HStack(spacing: 20){
                                                Image("MoneyBag").resizable().frame(width: 52, height: 59)
                                                VStack(alignment:.leading){
                                                    textStyle(text: "This Month You Spend", size: 18, weight: .semibold)
                                                    textStyle(text: "Rp. ", size: 18)
                                                }
                                                Spacer()
                                            }
                                            
                                            
                                            HStack{
                                                Spacer()
                                                textStyle(text: expandTotalSpend ? "close" : "details")
                                                Image(systemName: expandTotalSpend ? "chevron.up" : "chevron.down")
                                                    .font(Font.system(size: 12))
                                                    .foregroundStyle(Color.white)
                                            }
                                        }
                                        
                                        if expandTotalSpend{
                                            
                                            Capsule().fill(Color.white).frame(height: 1)
                                            
                                            ScrollView(.vertical, showsIndicators: true){
                                                LazyVStack(spacing: 30){
                                                    
                                                    var groupedItems: [String: [HMAccessory]] {
                                                        Dictionary(grouping: currentHMHome?.accessories ?? []) { accessory in
                                                            switch
                                                            accessory.category.categoryType {
                                                            case HMAccessoryCategoryTypeLightbulb: return "Lamp"
                                                            case HMAccessoryCategoryTypeAirConditioner: return "AC"
                                                            case  HMAccessoryCategoryTypeTelevision: return "Television"
                                                            default: return "Others"
                                                            }
                                                        }
                                                    }
                                                    let validCategories = sectionOrder.filter { groupedItems[$0] != nil }
                                                    
                                                    ForEach(Array(validCategories.enumerated()), id: \.element) { index, categoryType in
                                                        
                                                        
                                                        if let accessories = groupedItems[categoryType]{
                                                            
                                                            HStack(spacing: 20){
                                                                Image(systemName: logoNames[categoryType]!).font(Font.system(size: 35, weight: .thin))
                                                                VStack(alignment:.leading){
                                                                    textStyle(text: categoryType, size: 15, weight: .semibold)
                                                                    textStyle(text: "Rp. ", size: 15)
                                                                }
                                                                Spacer()
                                                            }
                                                            
                                                            if index < validCategories.count - 1{
                                                                Capsule().fill(Color.white).frame(height: 0.7).padding(.trailing, 22)
                                                            }
                                                        }
                                                    }
                                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                                    
                                                }
                                            }.frame(maxHeight: 200)
                                        }
                                    }
                                }.padding(.horizontal, 22)
                                    .padding(.top, 22)
                                    .padding(.bottom, expandTotalSpend ? 22 : 12)
                                    .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                            }
                            
                            .listRowBackground(Color.clear)
                            
                        }else{
                            HStack{
                                Spacer()
                                textStyle(text: "Add accessory to your home")
                                Spacer()
                            }.padding().glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listSectionSeparator(.hidden)
                    
                    VStack{
                        
                    }.frame(height:100)
                        .listRowBackground(Color.clear)
                        .listSectionSeparator(.hidden)
                    
                }
                .listStyle(.plain)
                
            }
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button{
                        showAddHomeSheet.toggle()
                        newHomeName = ""
                    }label:{
                        Image(systemName:"plus")
                    }.foregroundStyle(Color.white)
                }
                
                ToolbarItem(placement: .topBarTrailing){
                    Menu{
                        ForEach(homeObjList, id: \.self){ home in
                            Button{
                                currentHome = home
                                currentHMHome = homeStore.homes.first(where: { $0.name == currentHome?.homeName })
                            }label:{
                                textStyle(text: home.homeName, size: 16)
                                if currentHome?.homeName == home.homeName{
                                    textStyle(text: "Current Location", size: 12)
//                                    Image(systemName: "checkmark")
                                }
                                
                            }
                        }
                    }label:{
                        Image(systemName: "ellipsis")
                    }.foregroundStyle(Color.white)
                    
                }
                
                
            }
        }.sheet(isPresented: $showAddHomeSheet){
            
            ZStack{
                VStack(alignment: .leading, spacing: 30){
                    HStack{
                        Button{
                            showAddHomeSheet = false
                        }label:{
                            Image(systemName: "xmark").foregroundStyle(Color.white)
                        }
                        Spacer()
                        Text("New Home")
                        Spacer()
                        Button{
                            if let selectedCapacity = selection{
                                res = homeStore.createHome(homeName: newHomeName)
                                
                                if res[0] == "success"{
                                    context.insert(Home(kwHlimit: EcapacityDict[selectedCapacity]!, homeName: newHomeName))
                                    showAddHomeSheet = false
                                }
                                else{
                                    popUpError.toggle()
                                }
                            }
                            
                            
                        }label:{
                            Image(systemName: "checkmark").resizable()
                                .scaledToFit().padding()
                                .frame(width: 40, height: 40)
                        }.glassEffect(.clear)
                    }
                    
                    textStyle(text: "Home Name", size:16)
                    TextField("Home Name", text: $newHomeName).padding().background(Color.white).foregroundStyle(Color.black)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1.0))
                    
                    VStack(spacing: 20){
                        
                        
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
                    Spacer()
                }.padding()
                    .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                
                if popUpError{
                    Text(res[1])
                    Button("Close"){
                        popUpError.toggle()
                    }.padding().background(Color.blue)
                }
            }
        }.onAppear{
            updateSwiftData()
        }
        .onChange(of: homeStore.homes) { _ in
            updateSwiftData()
        }
        
    }
    
    func updateSwiftData(){
        let descriptor = FetchDescriptor<Home>()

        do {
            var items = try context.fetch(descriptor)
            let homeNamesInData = items.map(\.homeName)
            currentHMHome = nil
            for home in homeStore.homes {
                if !homeNamesInData.contains(home.name){
                    print("add: \(home.name)")
                    context.insert(Home(homeName: home.name))
                }
                if home.isPrimary{
                    currentHMHome = home
                }
            }
            
            items = try context.fetch(descriptor)
            
            for homeObj in items {
                let homeExist = homeStore.homes.first(where: {$0.name == homeObj.homeName})
                if homeExist == nil{
                    print("delete: \(homeObj.homeName)")
                    context.delete(homeObj)
                }
            }
            
            items = try context.fetch(descriptor).sorted{$0.homeName < $1.homeName}
            homeObjList = items
            if currentHMHome != nil {currentHome = items.first(where: {$0.homeName == currentHMHome!.name})}
            print("current home: \(currentHome?.homeName ?? "no current home")")
            
        } catch {
            print(error)
        }
    }
}
#Preview {
    MainPageView()
}
