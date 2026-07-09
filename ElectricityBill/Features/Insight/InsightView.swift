//
//  InsightView.swift
//  ElectricityBill
//
//  Created by Keira on 02/07/26.
//

import SwiftData
import SwiftUI

struct InsightView: View {
    @State var viewModel = InsightViewModel()
    @State var currentPage = 0
    private var usageBodyMessage: String {
        viewModel.pages.first(where: { $0.id == 0 })?.card?.bodyMessage ?? ""
    }
    @EnvironmentObject var appState: AppState
    @Query var accessories: [DeviceModel]
    
    var body: some View {
        ZStack {
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    LightningBolt()
                        .fill(usageBodyMessage.localizedCaseInsensitiveContains("increase") ? .red : .green)
                        .frame(width: 150, height: 220)
                        .overlay(
                            LightningBolt()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                                .shadow(color: .white, radius: 5)
                                .shadow(color: .white, radius: 15)
                                .shadow(color: .white, radius: 25)
                        )
                    
                    TabView(selection: $currentPage) {
                        ForEach(viewModel.pages) { page in
                            InsightCardView(card: page.card, isLoading: viewModel.isLoading)
                                .tag(page.id)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 150)
                    
                    VStack{
                        Text("Most Used in hours")
                            .padding()
                        mostUsedHrs
                        Spacer()
                        Text("Most Used in Watt")
                            .padding()
                        mostUsedWatt
                        Text("Most Spending")
                            .padding()
                        mostSpending
                    }
                    .padding(.bottom, 100)
                    
                    
                    
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
            }
        }
        .task {
            await viewModel.loadInsightsIfNeeded(currHome: appState.currentHome!)
        }
    }
    
    private var mostUsedHrs: some View{
        
        VStack{
            ForEach(
                accessories
                    .filter{$0.home == appState.currentHome}
                    .sorted{
                        $0.getTotalDuration(month: Date(), unit: .m) > $1.getTotalDuration(month: Date(), unit: .m)
                    }
                    .prefix(3)
            ) {  device in
                
                HStack() {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: logoNames[device.category]!)
                            .foregroundStyle(Color.white)
                    }
                    
                    Text (device.name)
                        .font(.subheadline)
                        .tint(.white)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text (formattedDuration(totalDurationMinutes: device.getTotalDuration(month: Date(), unit: .m)))
                        .font(.subheadline)
                        .tint(.white)
                        .opacity(0.55)
                }
                .padding(.vertical, 12)
                
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
    }
    
    private var mostUsedWatt: some View{
        VStack{
            ForEach(
                accessories
                    .filter{$0.home == appState.currentHome}
                    .sorted{
                        $0.getTotalWattDevice(month: Date()) > $1.getTotalWattDevice(month: Date())
                    }
                    .prefix(3)
            ) {  device in
                HStack() {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: logoNames[device.category]!)
                            .foregroundStyle(Color.white)
                    }
                    
                    Text(device.name)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text ("\(device.getTotalWattDevice(month: Date())) Watt")
                        .tint(.white)
                        .opacity(0.55)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
    }
    
    private var mostSpending: some View{
        VStack{
            ForEach(
                accessories
                    .filter{$0.home == appState.currentHome}
                    .sorted{
                        $0.getTotalSpendDevice(month: Date(), home: appState.currentHome!) > $1.getTotalSpendDevice(month: Date(), home: appState.currentHome!)
                    }
                    .prefix(3)
            ) {  device in
                HStack() {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: logoNames[device.category]!)
                            .foregroundStyle(Color.white)
                    }
                    
                    Text(device.name)
                        .fontWeight(.medium)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(formatToIDR(amount: device.getTotalSpendDevice(month: Date(), home: appState.currentHome!)))
                        .tint(.white)
                        .opacity(0.55)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
    }
    
    
}


private struct InsightCardView: View {
    let card: EnergyInsightCard?
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let card {
                Text(card.title)
                    .font(.body)
                    .fontWeight(.bold)
                Text(card.bodyMessage)
                    .font(.subheadline)
                    .tint(.white)
                    .opacity(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            } else if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.clear, in: .rect(cornerRadius: 24))
    }
}


#Preview {
    InsightView()
}
