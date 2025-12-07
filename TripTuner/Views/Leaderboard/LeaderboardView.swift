//
//  LeaderboardView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1).ignoresSafeArea()
            
            ScrollView {
                    VStack(spacing: 0) {
                        // Leaderboard Title
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.pennRed.opacity(0.8))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            
                            Text("Leaderboard")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.pennRed)
                            
                            Spacer()
                        }
                        .padding(20)
                        
                        // Time Period Selector
                        HStack(spacing: 12) {
                            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    viewModel.selectPeriod(period)
                                }) {
                                    Text(period.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(viewModel.selectedPeriod == period ? .white : .pennRed)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(viewModel.selectedPeriod == period ? Color.pennRed : Color.white)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(viewModel.selectedPeriod == period ? Color.clear : Color.pennRed, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        
                        // Top 3 Podium
                        HStack(alignment: .bottom, spacing: 12) {
                            // 2nd Place
                            if viewModel.topThree.count > 1 {
                                PodiumView(entry: viewModel.topThree[1], rank: 2)
                            }
                            
                            // 1st Place
                            if !viewModel.topThree.isEmpty {
                                PodiumView(entry: viewModel.topThree[0], rank: 1)
                            }
                            
                            // 3rd Place
                            if viewModel.topThree.count > 2 {
                                PodiumView(entry: viewModel.topThree[2], rank: 3)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        
                        // Public Entries (Top 10, excluding top 3)
                        if !viewModel.publicEntries.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(viewModel.publicEntries) { entry in
                                    LeaderboardRowView(entry: entry)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                    
                                    Divider()
                                        .padding(.leading, 20)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        
                        // Current User's Private Rank
                        if let userEntry = viewModel.currentUserEntry,
                           userEntry.rank > 10 {
                            VStack(spacing: 12) {
                                Divider()
                                    .padding(.horizontal, 20)
                                
                                HStack {
                                    Text("Your Rank")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("#\(userEntry.rank)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.pennRed)
                                }
                                .padding(.horizontal, 20)
                                
                                LeaderboardRowView(entry: userEntry)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .background(Color.white)
            }
        
        .onAppear {
            // Always load profile pictures when view appears
            viewModel.loadProfilePictures()
        }
    }
}

struct PodiumView: View {
    let entry: LeaderboardEntry
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return .pennRed
        case 2: return .gray
        case 3: return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Profile picture
                if let profileImageURL = entry.user.profileImageURL, !profileImageURL.isEmpty,
                   let url = URL(string: profileImageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: rank == 1 ? 80 : 60, height: rank == 1 ? 80 : 60)
                                .overlay(
                                    ProgressView()
                                        .tint(.gray)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: rank == 1 ? 80 : 60, height: rank == 1 ? 80 : 60)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: rank == 1 ? 80 : 60, height: rank == 1 ? 80 : 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: rank == 1 ? 80 : 60, height: rank == 1 ? 80 : 60)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: rank == 1 ? 80 : 60, height: rank == 1 ? 80 : 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 24, height: 24)
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: rank == 1 ? 8 : 4, y: rank == 1 ? 8 : 4)
            }
            
            Text(entry.user.name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text("\(entry.points) points")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(rankColor.opacity(0.2))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 40)
            
            // Profile picture
            if let profileImageURL = entry.user.profileImageURL, !profileImageURL.isEmpty,
               let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                ProgressView()
                                    .tint(.gray)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 20))
                            )
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: 4) {
                    Text(entry.user.handle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if let emoji = entry.badgeEmoji {
                        Text(emoji)
                            .font(.system(size: 12))
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.points)")
                    .font(.system(size: 16, weight: .semibold))
                Text("\(entry.tripCount) trips")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    LeaderboardView()
}

