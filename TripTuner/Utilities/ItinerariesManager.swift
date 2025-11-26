//
//  ItinerariesManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI

class ItinerariesManager: ObservableObject {
    static let shared = ItinerariesManager()
    
    @Published var itineraries: [Itinerary] = MockData.sampleItineraries
    
    private init() {
        loadItineraries()
    }
    
    func loadItineraries() {
        // In a real app, this would load from backend
        itineraries = MockData.sampleItineraries
        syncWithLikedManager()
    }
    
    func syncWithLikedManager() {
        let likedManager = LikedItinerariesManager.shared
        for index in itineraries.indices {
            // Update like count from persisted state
            let persistedCount = likedManager.getLikeCount(for: itineraries[index].id, defaultCount: itineraries[index].likes)
            itineraries[index].likes = persistedCount
            
            // Update isLiked state
            itineraries[index].isLiked = likedManager.isLiked(itineraries[index].id)
        }
    }
    
    func addItinerary(_ itinerary: Itinerary) {
        itineraries.insert(itinerary, at: 0)
    }
    
    func updateItinerary(_ itinerary: Itinerary) {
        if let index = itineraries.firstIndex(where: { $0.id == itinerary.id }) {
            itineraries[index] = itinerary
        }
    }
    
    func updateLikeCount(for itineraryID: String, newCount: Int) {
        if let index = itineraries.firstIndex(where: { $0.id == itineraryID }) {
            itineraries[index].likes = newCount
            itineraries[index].isLiked = LikedItinerariesManager.shared.isLiked(itineraryID)
        }
    }
}

