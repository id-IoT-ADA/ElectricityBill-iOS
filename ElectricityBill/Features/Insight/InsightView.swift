//
//  InsightView.swift
//  ElectricityBill
//
//  Created by Keira on 02/07/26.
//

import SwiftUI

struct InsightView: View {
    @StateObject var viewModel = InsightViewModel()
    @State var currentPage = 0
    private var usageBodyMessage: String {
        viewModel.pages.first(where: { $0.id == 0 })?.card?.bodyMessage ?? ""
    }
    
    
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
                    
//                    PageDots(count: viewModel.pages.count, current: currentPage)
                    
                    mostUsedSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
            }
        }
        .task {
            await viewModel.loadInsightsIfNeeded()
        }
    }
    
    
    private var mostUsedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            textStyle(text: "Most Used", size: 22, weight: .semibold)
            
            ForEach(Array(viewModel.mostUsedDevices.enumerated()), id: \.element.id) { index, device in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 40, height: 40)
//                        Image(systemName: device.icon)
//                            .foregroundStyle(Color.white)
                    }
                    
                    textStyle(text: device.name, size: 15, weight: .medium)
                    
                    Spacer()
                    
                    textStyle(text: device.usageRecords.formattedDuration(forMonth: .now), size: 14, color: .white.opacity(0.55))
                }
                .padding(.vertical, 12)
                
                if index < viewModel.mostUsedDevices.count - 1 {
                    Divider().overlay(Color.white.opacity(0.15))
                }
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
                textStyle(text: card.title, size: 19, weight: .bold)
                textStyle(text: card.bodyMessage, size: 14, color: .white.opacity(0.85))
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

private struct PageDots: View {
    let count: Int
    let current: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

#Preview {
    InsightView()
}
