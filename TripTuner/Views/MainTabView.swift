//
//  MainTabView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Add Post", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.pennRed)
        .sheet(isPresented: $showAddItinerary) {
            AddItineraryView()
                .environmentObject(authViewModel)
        }
    }
}

struct AddPostTabView: View {
    @Binding var showAddItinerary: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var itinerariesManager = ItinerariesManager.shared
    @State private var selectedItinerary: Itinerary?
    
    var myCreatedItineraries: [Itinerary] {
        guard let currentUserID = authViewModel.currentUser?.id else {
            return []
        }
        return itinerariesManager.itineraries.filter { $0.authorID == currentUserID }
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
                                    }) {
                                        VStack(alignment: .leading, spacing: 0) {
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
                                                
                                                // Show photo if available, otherwise show emoji
                                                if let firstPhotoURL = itinerary.photos.first, !firstPhotoURL.isEmpty,
                                                   let url = URL(string: firstPhotoURL) {
                                                    AsyncImage(url: url) { phase in
                                                        switch phase {
                                                        case .empty:
                                                            Text(itinerary.category.emoji)
                                                                .font(.system(size: 40))
                                                        case .success(let image):
                                                            image
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(height: 120)
                                                                .clipped()
                                                                .cornerRadius(12)
                                                        case .failure:
                                                            Text(itinerary.category.emoji)
                                                                .font(.system(size: 40))
                                                        @unknown default:
                                                            Text(itinerary.category.emoji)
                                                                .font(.system(size: 40))
                                                        }
                                                    }
                                                } else {
                                                    Text(itinerary.category.emoji)
                                                        .font(.system(size: 40))
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(itinerary.title)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.black)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                    .padding(.top, 12)
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "hand.thumbsup.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.pennRed)
                                                    Text("\(LikedItinerariesManager.shared.getLikeCount(for: itinerary.id, defaultCount: itinerary.likes))")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.bottom, 12)
                                            }
                                            .padding(.horizontal, 12)
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

