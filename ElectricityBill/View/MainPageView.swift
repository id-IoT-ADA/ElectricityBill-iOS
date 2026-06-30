//
//  MainPageView.swift
//  ElectricityBill
//
//  Created by Karen Regina Susanto on 28/06/26.
//

import SwiftUI
import HomeKit

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
    @StateObject private var homeStore = HomeStore()
    @State var usedkWh: Double = 0.0
    @State var expandTotalSpend = false
    
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
                                        textStyle(text:"1200 kWh", size: 12, color: .white.opacity(0.55))
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
                                                ForEach(0..<3){i in
                                                    
                                                    HStack(spacing: 20){
                                                        Image(systemName: "tv").font(Font.system(size: 35, weight: .thin))
                                                        VStack(alignment:.leading){
                                                            textStyle(text: "Television", size: 15, weight: .semibold)
                                                            textStyle(text: "Rp. ", size: 15)
                                                        }
                                                        Spacer()
                                                    }
                                                    
                                                    if i < 3-1{
                                                        Capsule().fill(Color.white).frame(height: 0.7).padding(.trailing, 22)
                                                    }
                                                }
                                                .transition(.opacity.combined(with: .move(edge: .top)))
                                            }
                                        }.frame(height: 200)
                                    }
                                }
                            }.padding(.horizontal, 22)
                                .padding(.top, 22)
                                .padding(.bottom, 12)
                                .glassEffect(.clear, in: .rect(cornerRadius: 12.0))
                        }
                        
                        .listRowBackground(Color.clear)
                    }
                    .listSectionSeparator(.hidden)
//                    Button{
//                        progress += 0.1
//                        
//                    }label:{
//                        Image(systemName: "plus").frame(height:50)
//                    }.listRowBackground(Color.clear).foregroundStyle(Color.white)
//                    //
//                    Button{
//                        progress -= 0.1
//                        
//                    }label:{
//                        Image(systemName: "minus").frame(height:50)
//                    }.listRowBackground(Color.clear).foregroundStyle(Color.white)
                    
//                    if !homeStore.homes.isEmpty {
//                        
//                        ForEach(homeStore.homes, id: \.uniqueIdentifier) { home in
//                            Section{
//                                textStyle(text: home.name, size: 20)
//                                    .listRowBackground(Color.clear)
//                            }
//                            .listRowBackground(Color.clear)
//                        }.background(.clear)
//                        
//                    }
//                    else{
//                        Section{
//                            textStyle(text: "No Home Found", size: 20).listRowBackground(Color.clear)
//                        }.listRowBackground(Color.clear)
//                    }
                    
                }
                .listStyle(.plain)
                
            }
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Menu{
                        Text("Menu 1")
                        Text("Menu 2")
                    }label:{
                        Image(systemName: "ellipsis")
                    }.foregroundStyle(Color.white)
                    
                }
            }
        }
        
    }
}
#Preview {
    MainPageView()
}
