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

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if homeStore.isLoaded{
                    TabView {
                        Tab("Home", systemImage: "house.fill"){
                            MainPageView().toolbar(
                                appState.currentHome?.VACapacity == 0 ? .hidden : .visible,
                                for: .tabBar
                            )
                        }
                        Tab("Monitor", systemImage: "inset.filled.rectangle.and.person.filled") {
                            MonitoringView()
                        }
                        Tab("Insight", systemImage: "lightbulb.circle.fill") {
                            InsightView()
                        }
                    }
                    .foregroundStyle(Color(.white))
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
