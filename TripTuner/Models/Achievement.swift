//
//  Achievement.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var emoji: String
    var unlockedAt: Date?
    var isUnlocked: Bool {
        unlockedAt != nil
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         emoji: String,
         unlockedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.emoji = emoji
        self.unlockedAt = unlockedAt
    }
}

