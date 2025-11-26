//
//  MainTabView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddItinerary = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(1)
            
            Button(action: {
                showAddItinerary = true
            }) {
                VStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                    Text("Add Post")
                        .font(.system(size: 12))
                }
            }
            .tabItem {
                Label("Add Post", systemImage: "plus.circle.fill")
            }
            .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.pennRed)
        .sheet(isPresented: $showAddItinerary) {
            AddItineraryView()
        }
    }
}

#Preview {
    MainTabView()
}

