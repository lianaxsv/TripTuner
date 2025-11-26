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
    }
    
    func addItinerary(_ itinerary: Itinerary) {
        itineraries.insert(itinerary, at: 0)
    }
    
    func updateItinerary(_ itinerary: Itinerary) {
        if let index = itineraries.firstIndex(where: { $0.id == itinerary.id }) {
            itineraries[index] = itinerary
        }
    }
}

