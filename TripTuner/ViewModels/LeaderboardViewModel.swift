//
//  LeaderboardViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI

enum LeaderboardPeriod: String, CaseIterable {
    case thisMonth = "This Month"
    case allTime = "All Time"
}

class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = MockData.leaderboardEntries
    @Published var selectedPeriod: LeaderboardPeriod = .thisMonth
    @Published var isLoading = false
    
    var topThree: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }
    
    var remainingEntries: [LeaderboardEntry] {
        Array(entries.dropFirst(3))
    }
    
    func selectPeriod(_ period: LeaderboardPeriod) {
        selectedPeriod = period
        refreshLeaderboard()
    }
    
    func refreshLeaderboard() {
        isLoading = true
        // Mock refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.entries = MockData.leaderboardEntries
            self.isLoading = false
        }
    }
}

