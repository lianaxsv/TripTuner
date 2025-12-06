//
//  LeaderboardViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import Combine

enum LeaderboardPeriod: String, CaseIterable {
    case thisMonth = "This Month"
    case allTime = "All Time"
}

class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var selectedPeriod: LeaderboardPeriod = .thisMonth
    @Published var isLoading = false
    
    private let itinerariesManager = ItinerariesManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadLeaderboard()
        // Observe changes to itineraries to update leaderboard
        itinerariesManager.$itineraries
            .sink { [weak self] _ in
                self?.loadLeaderboard()
            }
            .store(in: &cancellables)
    }
    
    var topThree: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }
    
    var remainingEntries: [LeaderboardEntry] {
        Array(entries.dropFirst(3))
    }
    
    func selectPeriod(_ period: LeaderboardPeriod) {
        selectedPeriod = period
        loadLeaderboard()
    }
    
    func loadLeaderboard() {
        isLoading = true
        
        // Calculate points from upvotes on itineraries
        var userPoints: [String: Int] = [:] // userID -> total upvotes
        var userItineraryCount: [String: Int] = [:] // userID -> itinerary count
        var userInfo: [String: (name: String, handle: String)] = [:] // userID -> user info
        
        let dateFilter: Date?
        if selectedPeriod == .thisMonth {
            let calendar = Calendar.current
            dateFilter = calendar.date(byAdding: .month, value: -1, to: Date())
        } else {
            dateFilter = nil
        }
        
        // Process all itineraries to calculate points
        for itinerary in itinerariesManager.itineraries {
            // Filter by date if needed
            if let dateFilter = dateFilter, itinerary.createdAt < dateFilter {
                continue
            }
            
            let userId = itinerary.authorID
            let upvotes = itinerary.likes
            
            // Sum upvotes as points
            userPoints[userId, default: 0] += upvotes
            userItineraryCount[userId, default: 0] += 1
            
            // Store user info from itinerary
            if userInfo[userId] == nil {
                userInfo[userId] = (name: itinerary.authorName, handle: itinerary.authorHandle)
            }
        }
        
        // Create leaderboard entries from all users who have itineraries
        var leaderboardEntries: [LeaderboardEntry] = []
        
        // Process users from itineraries
        for (userId, points) in userPoints {
            if let info = userInfo[userId] {
                let user = User(
                    id: userId,
                    name: info.name,
                    email: "",
                    points: points,
                    handle: info.handle
                )
                let entry = LeaderboardEntry(
                    user: user,
                    rank: 0, // Will be set after sorting
                    points: points,
                    tripCount: userItineraryCount[userId] ?? 0
                )
                leaderboardEntries.append(entry)
            }
        }
        
        // Also include mock users who don't have itineraries yet (for variety)
        for mockUser in MockData.sampleUsers {
            if !userPoints.keys.contains(mockUser.id) {
                // User has no itineraries, so 0 points
                let entry = LeaderboardEntry(
                    user: mockUser,
                    rank: 0,
                    points: 0,
                    tripCount: 0
                )
                leaderboardEntries.append(entry)
            }
        }
        
        // Sort by points (descending) and assign ranks
        leaderboardEntries.sort { $0.points > $1.points }
        for (index, _) in leaderboardEntries.enumerated() {
            leaderboardEntries[index].rank = index + 1
        }
        
        DispatchQueue.main.async {
            self.entries = leaderboardEntries
            self.isLoading = false
        }
    }
    
    func refreshLeaderboard() {
        loadLeaderboard()
    }
}

