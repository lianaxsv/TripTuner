//
//  LikedItinerariesManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI

class LikedItinerariesManager: ObservableObject {
    static let shared = LikedItinerariesManager()
    
    @Published var likedItineraryIDs: Set<String> = []
    @Published var itineraryLikeCounts: [String: Int] = [:] // itineraryID -> like count
    
    private init() {
        loadFromUserDefaults()
    }
    
    func loadFromUserDefaults() {
        // Load liked IDs
        if let data = UserDefaults.standard.data(forKey: "likedItineraryIDs"),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            likedItineraryIDs = ids
        }
        
        // Load like counts
        if let data = UserDefaults.standard.data(forKey: "itineraryLikeCounts"),
           let counts = try? JSONDecoder().decode([String: Int].self, from: data) {
            itineraryLikeCounts = counts
        }
    }
    
    func isLiked(_ itineraryID: String) -> Bool {
        likedItineraryIDs.contains(itineraryID)
    }
    
    func getLikeCount(for itineraryID: String, defaultCount: Int) -> Int {
        return itineraryLikeCounts[itineraryID] ?? defaultCount
    }
    
    func toggleLike(_ itineraryID: String, currentCount: Int) -> Int {
        let wasLiked = likedItineraryIDs.contains(itineraryID)
        
        if wasLiked {
            // Unlike
            likedItineraryIDs.remove(itineraryID)
            let newCount = max(0, currentCount - 1)
            itineraryLikeCounts[itineraryID] = newCount
            saveToUserDefaults()
            return newCount
        } else {
            // Like
            likedItineraryIDs.insert(itineraryID)
            let newCount = currentCount + 1
            itineraryLikeCounts[itineraryID] = newCount
            saveToUserDefaults()
            return newCount
        }
    }
    
    private func saveToUserDefaults() {
        // Save liked IDs
        if let data = try? JSONEncoder().encode(likedItineraryIDs) {
            UserDefaults.standard.set(data, forKey: "likedItineraryIDs")
        }
        
        // Save like counts
        if let data = try? JSONEncoder().encode(itineraryLikeCounts) {
            UserDefaults.standard.set(data, forKey: "itineraryLikeCounts")
        }
    }
    
    func updateItineraryLikeCount(_ itineraryID: String, count: Int) {
        itineraryLikeCounts[itineraryID] = count
        saveToUserDefaults()
    }
}

