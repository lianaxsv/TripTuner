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
            
            AddPostTabView(showAddItinerary: $showAddItinerary)
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

struct AddPostTabView: View {
    @Binding var showAddItinerary: Bool
    @StateObject private var itinerariesManager = ItinerariesManager.shared
    @State private var selectedItinerary: Itinerary?
    @State private var showItineraryDetail = false
    
    var myCreatedItineraries: [Itinerary] {
        itinerariesManager.itineraries.filter { $0.authorID == MockData.currentUserId }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if myCreatedItineraries.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.pennRed)
                        
                        Text("Create Your First Itinerary")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Share your favorite Philadelphia trips with the community!")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showAddItinerary = true
                        }) {
                            Text("Create Itinerary")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(Color.pennRed)
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("My Created Itineraries")
                                    .font(.system(size: 24, weight: .bold))
                                Spacer()
                                Button(action: {
                                    showAddItinerary = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.pennRed)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(myCreatedItineraries) { itinerary in
                                    Button(action: {
                                        selectedItinerary = itinerary
                                        showItineraryDetail = true
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color.pennRed.opacity(0.6), Color.pennBlue.opacity(0.6)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(height: 120)
                                                
                                                Text(itinerary.category.emoji)
                                                    .font(.system(size: 40))
                                            }
                                            
                                            Text(itinerary.title)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.black)
                                                .lineLimit(2)
                                            
                                            HStack {
                                                Image(systemName: "hand.thumbsup.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.pennRed)
                                                Text("\(itinerary.likes)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Add Post")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddItinerary = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.pennRed)
                    }
                }
            }
        }
        .sheet(item: $selectedItinerary) { itinerary in
            ItineraryDetailView(itinerary: itinerary)
        }
    }
}

#Preview {
    MainTabView()
}

