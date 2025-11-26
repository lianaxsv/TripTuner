//
//  LeaderboardEntry.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    var user: User
    var rank: Int
    var points: Int
    var tripCount: Int
    var badgeEmoji: String?
    
    init(id: String = UUID().uuidString,
         user: User,
         rank: Int,
         points: Int,
         tripCount: Int,
         badgeEmoji: String? = nil) {
        self.id = id
        self.user = user
        self.rank = rank
        self.points = points
        self.tripCount = tripCount
        self.badgeEmoji = badgeEmoji
    }
}

